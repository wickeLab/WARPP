import Rails from "@rails/ujs"
import { updateAccordion } from "./orobanchaceae_accordion"
import { changeTreeData } from "./d3_tree"
import { containerElement } from "./orobanchaceae_accordion";

export function toggleFilterOptions() {
    let a = window.getComputedStyle(document.getElementById('filter-container'))
    if (a.getPropertyValue('display') === 'none') {
        d3.select('#filter-container')
            .style('display', 'block')
            .style("border-left", "2px solid #e0e0e0")
            .style("padding", "5px 5px 0 10px");
    } else {
        d3.select('#filter-container')
            .style('display', 'none')
            .style("border-left", "none")
            .style("padding", "0");
    }
}

d3.select(".filter-form").append("div")
    .attr("class", "exit-button")
    .append("i")
    .attr("class", "fa fa-times")
    .style("position", "absolute")
    .style("right", "15px")
    .style("top", "15px")
    .style("cursor", "pointer")
    .attr("title", "Toggle filter options")
    .on("click", rejectChanges);

let lastSubmittedLifespan,
    lastSubmittedLifestyle,
    lastSubmittedInformationScore,
    lastSubmittedQueryType;

// Handler for dropdown value change
var submitFilter = function() {
    lastSubmittedLifespan = $("#lifespan-select").val();
    lastSubmittedLifestyle = $("#lifestyle-select").val();
    lastSubmittedInformationScore = $("#information-score-select").val();
    lastSubmittedQueryType = $("input[name='query-type']:checked").val();
    let dataToSend;

    if(lastSubmittedLifespan == "" && lastSubmittedLifestyle == "") {
        dataToSend = {
            family: gon.family
        }
    } else {
        let lifespanHash = {};
        let i = 1;
        lastSubmittedLifespan.forEach(function(d) {
            lifespanHash[`${i}`] = d;
            i++;
        });

        let lifestyleHash = {};
        i = 1;
        lastSubmittedLifestyle.forEach(function(d) {
            lifestyleHash[`${i}`] = d;
            i++;
        });

        dataToSend = {
            family: gon.family,
            filter_options: {
                lifestyle: lifestyleHash,
                lifespan: lifespanHash,
                information_score: lastSubmittedInformationScore,
                query_type: lastSubmittedQueryType
            }
        };
    }

    //ajax post to update gon.all_oros
    Rails.ajax({
        type: "POST",
        dataType: 'json',
        contentType: 'application/json',
        url: "/filter_tree",
        data: JSON.stringify(dataToSend),
        success: function(response) {
            var newData = JSON.parse(response["all_oros"]);
            var pieChartData = JSON.parse(response["information_score"]);
            toggleFilterOptions();
            containerElement.select("ul").remove();
            containerElement.select(".accordion-header").remove();
            updateAccordion(newData);
            changeTreeData(newData, pieChartData);
        }
    });
};

var filterFormTable = d3.select(".filter-form").append("table")
    .append("tbody");

filterFormTable.append("tr").append("td")
    .attr("colspan", "2")
    .text("Select what you are interested in...");

function createSelect(id, theseOptions, label) {
    var thisRow = filterFormTable.append("tr");

    thisRow.append("td")
        .html(label)
        .attr("id", `td-${id}`);

    var dropdown = thisRow.append("td")
        .append("select", "svg")
        .attr("class", "selectpicker")
        .attr("data-actions-box", "true")
        .attr("id", `${id}-select`)
        .attr("name", `filter_options[${id}][]`);

    if (id != 'information-score') {
        dropdown.attr("multiple", "multiple");
    }

    dropdown.selectAll("option")
        .data(theseOptions)
        .enter().append("option")
        .attr("value", function (d) { return d; })
        .text(function (d) {
            return d[0].toUpperCase() + d.slice(1,d.length); // capitalize 1st letter
        });

    $(".selectpicker").selectpicker();
}

var lifestyleLabel = "Lifestyle(s): ",
    lifespanLabel = "Lifespan(s): ",
    informationScoreLabel = "Information Availability<br><small>(at least)</small>: ";
createSelect("lifestyle", ["autotroph", "facultative", "obligate", "holoparasitic", "unknown"], lifestyleLabel);
createSelect("lifespan", ["annual", "biennial", "perennial", "unknown"], lifespanLabel);
createSelect("information-score", ["unknown", "meager", "decent", "good"], informationScoreLabel);

d3.selectAll(".dropdown-toggle")
    .attr("data-display", "static");

filterFormTable.append("tr").attr("height", 10);

function createButton(id, text, toDo) {
    var button = filterFormTable.append("tr");

    button.append("td");
    button.append("td")
        .append("button", "svg")
        .attr("class", "btn")
        .attr("width", "100% !important")
        .attr("id", id)
        .text(text)
        .style("text-align", "center")
        .on("click", toDo);

    if (button.id == "submit-filter") {
        button.attr("type", "submit")
    }
}

function rejectChanges() {
    $("#lifespan-select").val(lastSubmittedLifespan);
    $("#lifestyle-select").val(lastSubmittedLifestyle);
    $("#information-score-select").val(lastSubmittedInformationScore);
    $("input[name='query-type']:checked").val(lastSubmittedQueryType);

    if (lastSubmittedQueryType == 'independently') {
        $("#label-combined").removeClass('active focus');
        $("#label-independently").removeClass('active focus').addClass('active focus');
    } else {
        $("#label-independently").removeClass('active focus');
        $("#label-combined").removeClass('active focus').addClass('active focus');
    }

    $(".selectpicker").selectpicker("refresh");

    toggleFilterOptions();
}

function resetTree() {
    $("#label-combined").removeClass('active focus');
    $("#label-independently").removeClass('active focus').addClass('active focus');
    $(".selectpicker").val("");
    $("#information-score-select").val("unknown");
    $(".selectpicker").selectpicker("refresh");

    submitFilter();
}

var radioButton = filterFormTable.append("tr");

radioButton.append("td")
    .attr("colspan", "2")
    .html("Do you want to select for traits<br>" +
        "<b>independently</b> (min. one trait in total)<br>" +
        "or in <b>combination</b> (one trait per category)? " +
        "Information availability will not be affected by this choice.");

var radioButton = filterFormTable.append("tr");

var formCheckTd  = radioButton.append("td")
    .attr("colspan", "2");

var formCheck = formCheckTd.append("div")
    .attr("class", "btn-group btn-group-toggle")
    .attr("width", "100% !important")
    .attr("data-toggle", "buttons");

formCheck.append("label")
    .attr("id", "label-independently")
    .attr("class", "btn btn-secondary active")
    .text("independently")
    .append("input")
    .attr("type", "radio")
    .attr("name", "query-type")
    .attr("id", "option1")
    .attr("value", "independently")
    .attr("autocomplete", "off")
    .attr("checked", "true");

formCheck.append("label")
    .attr("id", "label-combined")
    .style("flex-basis", "calc(60% - 10px)")
    .attr("class", "btn btn-secondary")
    .text("combined")
    .append("input")
    .attr("type", "radio")
    .attr("name", "query-type")
    .attr("id", "option2")
    .attr("value", "combined")
    .attr("autocomplete", "off");

filterFormTable.append("tr").attr("height", 10);

createButton("submit-filter", "Go", submitFilter);
createButton("reset-button", "Reset tree", resetTree);
createButton("reject-button", "Reject changes and exit", rejectChanges);