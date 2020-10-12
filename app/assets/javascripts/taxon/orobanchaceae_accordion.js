var containerElement = d3.select(".accordion-container");

function addTableContent(d, parentElement) {
    let trParent = parentElement.append("tr");
    let tdParent = trParent.append("td");
    let tdLink = tdParent.append("a")
        .attr("id", d.data.information_score)
        .attr("class", "taxonomicAccordionLink")
        .attr("href", `/taxa/search/${d.data.name}`)
        .text(d.data.name);
}

function addAccordionCard(d, parentAccordion) {
    let accordionCard = parentAccordion.append("div")
        .attr("class", "card");

    let cardHeader = accordionCard.append("div")
        .attr("class", "card-header")
        .attr("id", `heading-${d.data.name}`);
    let cardButton = cardHeader.append("button")
        .attr("class", "btn btn-link collapsed")
        .attr("type", "button")
        .attr("data-toggle", "collapse")
        .attr("data-target", `#collapse-${d.data.name}`)
        .attr("aria-expanded", "false")
        .attr("aria-controls", `collapse-${d.data.name}`);

    if (d.children) {
        cardButton.html('<i class="fa fa-plus"></i>' + d.data.name);
    } else {
        cardButton.html(d.data.name);
    }

    let cardCollapse = accordionCard.append("div")
        .attr("id", `collapse-${d.data.name}`)
        .attr("class", "collapse")
        .attr("aria-labelledby", `heading-${d.data.name}`);

    if (d.children) {
        let cardBody = cardCollapse.append("div")
            .attr("class", "card-body");
        let tableParent = cardBody.append("table");
        let tableBody = tableParent.append("tbody");

        d.children.forEach(function(d) {
            addTableContent(d, tableBody)
        })
    }
}

function addAccordion(d, parentElement) {
    let rootDiv = parentElement.append("div")
        .attr("id", `accordion-${d.data.name}`) // TODO need multiple accordions for Orobanchaceae e.g.
        .attr("class", "accordion");
    return rootDiv
}

function addList(d, parentElement) {
    let listItem = parentElement.append("li")
        .attr("id", `${d.data.name}-li`);

    if (d.depth > 0) {
        listItem.html(d.data.name);
    }

    if (d.depth < maxDepth - 2) {
        d.children.forEach(function(d) {
            let parentList = listItem.append("ul");
            addList(d, parentList)
        })
    } else {
        let parentAccordion = addAccordion(d, listItem);
        d.children.forEach(function(d) {
            addAccordionCard(d, parentAccordion)
        })
    }
}

function updateAccordion(data) {
    var root = d3.hierarchy(data, function(d) { return d.children; });
    const accordionContainer = d3.select(".accordion-container");

    const headerContainer = accordionContainer.append("div")
        .attr("class", "accordion-header")
        .style("display", "flex");

    headerContainer.append("h5")
        .html(root.data.name);

    headerContainer.append("button", "svg")
        .style("margin-left", "auto")
        .attr("type", "submit")
        .attr("class", "btn")
        .attr("id", "toggle-filter-options")
        .attr("title", "Filter tree")
        .on("click", toggleFilterOptions)
        .html('<i class="fa fa-filter"></i>');

    let parentList = accordionContainer.append("ul");

    if (maxDepth === 2) {
        let listItem = parentList.append("li")
            .attr("id", `${root.data.name}-li`);

        let parentAccordion = addAccordion(root, listItem);
        root.children.forEach(function(d) {
            addAccordionCard(d, parentAccordion)
        })
    } else {
        root.children.forEach(function(d) {
            addList(d, parentList)
        })
    }
}

var data = JSON.parse(gon.all_oros);
var maxDepth = gon.max_depth;
updateAccordion(data);

$(function(){
    $(document)
        .on('show.bs.collapse', '.collapse', function(){
            $(this).prev(".card-header").find(".fa").removeClass("fa-plus").addClass("fa-minus");
        })
        .on('hide.bs.collapse', '.collapse', function(){
            $(this).prev(".card-header").find(".fa").removeClass("fa-minus").addClass("fa-plus");
        })
        .on('shown.bs.collapse', '.collapse', function(){
            update(root);
        }).on('hidden.bs.collapse', '.collapse', function() {
            update(root);
        });
});