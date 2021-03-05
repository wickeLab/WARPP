var trees = JSON.parse(gon.trait_reconstruction_trees);

//globals
var depth = 0;

// Pie chart color selection
var colorSelection = {
    "lifespan": [customColors["annual"], customColors["biennial"], customColors["perennial"]],
    "lifestyle": [customColors["autotroph"], customColors["facultative"], customColors["obligate"], customColors["holoparasitic"]]
};

// Set the dimensions and margins of the diagram
var margin = {top: 20, right: 40, bottom: 30, left: 100},
    width = 950 - margin.left - margin.right,
    height = 485 - margin.top - margin.bottom;

var i = 0,
    duration = 600,
    root,
    svg;

// declares a tree layout and assigns the size
var treemap = d3.tree().size([height, width]);

var tooltipDiv = d3.select(".trait-rec-pie-zoom").append("div")
    .attr("class", "tooltip-legend")
    .style("opacity", 0);

var jumps = [],
    taxa = [],
    genera = [];

function collapseAfterFourthLevel(source) {
    source.children.forEach( function(d) {
        if (d.children) {
            d.children.forEach( function(d) {
                if (d.children) {
                    d.children.forEach(collapse);
                }
            });
        }
    });
}

// Collapse the node and all it's children
function collapse(d) {
    if (d.children) {
        d._children = d.children;
        d._children.forEach(collapse);
        d.children = null
    }
}

// Collapse the node and all it's children
function expand(d) {
    if (d._children) {
        d.children = d._children;
        d._children = null
    }
    if (d.children) {
        d.children.forEach(expand);
    }
}

function showTooltip(listToProject) {
    d3.select(".tree-leaves").remove();

    var ulParent = d3.select(".js-tooltip")
        .append("ul")
        .style("padding-left", 0)
        .style("list-style-position", "inside")
        .attr("class", "tree-leaves");

    listToProject.forEach(function (d) {
        const liParent = ulParent.append("li")
            .html(d)
            .style("padding-left", "15px")
            .style("text-indent", "-13px")
            .style("list-style-type", "circle")
            .style("text-align", "left");
    })
}

// code is based on d3noob's collapsible tree diagram in v4
// https://bl.ocks.org/d3noob/43a860bc0024792f8803bba8ca0d5ecd
function update(source) {

    // Assigns the x and y position for the nodes
    var treeData = treemap(source);

    // Compute the new tree layout.
    var nodes = treeData.descendants(),
        links = treeData.descendants().slice(1);

    // Normalize for fixed-depth.
    nodes.forEach(function(d){ d.y = d.depth * 180});

    // Update the nodes...
    var node = svg.selectAll('g.node')
        .data(nodes, function(d) {return d.id || (d.id = ++i); });

    // Enter any new modes at the parent's previous position.
    var nodeEnter = node.enter().append('g')
        .attr('class', 'node')
        .attr('id', function(d) {
            return "node-" + d.data.name.replace(/\./g, '_').replace(/\s/g, '_');
        })
        .attr("transform", function(d) {
            return "translate(" + source.y0 + "," + source.x0 + ")";
        })
        .on('click', click)
        .on("mouseover", function(d) {
            if (!d.children && d._children) {
                var temporaryRoot = d3.hierarchy(data, function(d) { return d.children; });

                var temporarySubTree,
                    dName = d.data.name;

                temporaryRoot.each( function(d) {
                    if (d.data.name === dName) {
                        temporarySubTree = d.copy();
                        return false;
                    }
                });

                var hiddenTaxa = temporarySubTree.leaves().map (function(d) {
                    return d.data.name;
                });

                var hiddenTaxaList = hiddenTaxa.sort();

                showTooltip(hiddenTaxaList)
            }
            drawPieChart(d, false);
        });

    // Add labels for the nodes
    nodeEnter.append('text')
        .attr("dy", ".35em")
        .attr("x", function(d) {
            return d.children || d._children ? -3 : 28;
        })
        .attr("y", function(d) {
            return d.depth != 0 && (d.children || d._children) ? -7 : 0;
        })
        .attr("transform", function(d) {
            return d.depth != 0 && (d.children || d._children) ? "rotate(25)" : "rotate(0)";
        })
        .attr("text-anchor", function(d) {
            return d.children || d._children ? "end" : "start";
        })
        .text(function(d) {
            if (d.data.name.match(/[a-z]/i)) {
                return d.data.name;
            } else {
                return "node " + d.data.name;
            }
        });

    // Update
    var nodeUpdate = nodeEnter.merge(node);

    // Transition to the proper position for the node
    nodeUpdate.transition()
        .duration(duration)
        .attr("transform", function(d) {
            return "translate(" + d.y + "," + d.x + ")";
        });

    // Update the node attributes and style
    nodeUpdate.select('svg.node')
        .attr('cursor', 'pointer');

    // Remove any exiting nodes
    var nodeExit = node.exit().transition()
        .duration(duration)
        .attr("transform", function(d) {
            return "translate(" + source.y + "," + source.x + ")";
        })
        .remove();

    // On exit reduce the opacity of text labels
    nodeExit.select('text')
        .style('fill-opacity', 1e-6);

    // Update the links...
    var link = svg.selectAll('path.link')
        .data(links, function(d) { return d.id; });

    // Enter any new links at the parent's previous position.
    var linkEnter = link.enter().insert('path', "g")
        .attr("class", "link")
        .attr('d', function(d){
            var o = {x: source.x0, y: source.y0};
            return diagonal(o, o)
        });

    // Update
    var linkUpdate = linkEnter.merge(link);

    // Transition back to the parent element position
    linkUpdate.transition()
        .duration(duration)
        .attr('d', function(d){ return diagonal(d, d.parent) });

    // Remove any exiting links
    var linkExit = link.exit().transition()
        .duration(duration)
        .attr('d', function(d) {
            var o = {x: source.x, y: source.y};
            return diagonal(o, o)
        })
        .remove();

    // Store the old positions for transition.
    nodes.forEach(function(d){
        d.x0 = d.x;
        d.y0 = d.y;
    });

    // Creates a curved (diagonal) path from parent to the child nodes
    function diagonal(s, d) {

        path = `M ${s.y} ${s.x}
            C ${(s.y + d.y) / 2} ${s.x},
              ${(s.y + d.y) / 2} ${d.x},
              ${d.y} ${d.x}`;

        return path
    }

    // Toggle children on click.
    function click(d) {
        if (d.depth === 0) { // clicked on root node
            root = d3.hierarchy(data, function (d) { return d.children; });

            var newRoot = node;

            root.each(function (node) {
                if (node.data.name == d.data.name) {
                    if (jumps[jumps.length - 1] == 1) {
                        jumps.pop();
                        newRoot = node.parent;
                    } else if (jumps[jumps.length - 1] == 2) {
                        jumps.pop();
                        newRoot = node.parent.parent;
                    } else if (jumps[jumps.length - 1] == 3) {
                        jumps.pop();
                        newRoot = node.parent.parent.parent;
                    } else {
                        newRoot = node.parent;
                    }
                }
            });

            root = newRoot.copy();
        } else if (d._children) {
            d.children = d._children;
            d.children.forEach(expand);
            root = d.copy();
        } else if (d.children) {
            d.children.forEach(expand);
            root = d.copy();
        }

        if (d.depth > 0) {
            jumps.push(d.depth);
        }

        deleteTreeNodes();

        collapseAfterFourthLevel(root);
        update(root);

        root.each(function(d) {
            drawPieChart(d);
        });

        if ($("#tree-species").val() != "") {
            $("#tree-species").val("");
            $(".selectpicker").selectpicker("refresh");
        }
    }

    nodeUpdate.each(function(d) {
        drawPieChart(d);
    });
}

function deleteTreeNodes() {
    d3.select(".js-container").selectAll(".node").remove();
}

function drawPieChart(d, nodeElement = true) {
    var dName = d.data.name.replace(/\./g, '_').replace(/\s/g, '_'),
        dNameForTooltip = d.data.name;

    // Add Pie circle for the nodes
    var treeType = d3.select("#tree-trait").property('value');

    if (treeType == "lifespan") {
        var thisData = d.data.lifespan;
    } else {
        var thisData = d.data.lifestyle;
    }

    if (nodeElement) {
        var width = 25,
            height = 25,
            radius = Math.min(width, height)/2 - 3;
    } else {
        var width = 160,
            height = 160,
            radius = Math.min(width, height)/2 - 3;
    }

    var allValues = thisData.map(function(item) {return item.itemValue;});
    var sum = allValues.reduce(function(a, b) {
        return a + b;
    }, 0);

    if (sum == 0) {
        thisData = [{"itemLabel":"unknown","itemValue":1}];
        var dataLabels = ["unknown"];

        var colorRange = ["#f5f5f5"];

        var color = d3.scaleOrdinal()
            .domain(dataLabels)
            .range(colorRange);
    } else {
        var dataLabels = thisData.map(function(item) { return item.itemLabel; });

        var colorRange = colorSelection[treeType];

        var color = d3.scaleOrdinal()
            .domain(dataLabels)
            .range(colorRange);
    }

    var arc = d3.arc()
        .outerRadius(radius)
        .innerRadius(0);

    var arcBorder = d3.arc()
        .innerRadius(radius)
        .outerRadius(radius + 3);

    var pie = d3.pie()
        .sort(null)
        .value(function(d) { return d.itemValue; });

    if (nodeElement) {
        var elementName = `#node-${dName}`;
    } else {
        d3.select(".trait-rec-pie-zoom").select("svg").remove();
        var elementName = ".trait-rec-pie-zoom";
    }

    var svg_pie = d3.select(elementName).append("svg")
        .attr("y", -(height / 2))
        .attr("width", width)
        .attr("height", height)
        .attr("class", "traitRecPie")
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    var g_pie = svg_pie.selectAll(".arc")
        .data(pie(thisData))
        .enter().append("g")
        .attr("class", "arc");

    var g_path = g_pie.append("path")
        .attr("d", arc)
        .style("fill", function(d, i) {
            return color(thisData[i].itemLabel);
        });

    if (!nodeElement) {
        tooltipDiv.transition()
            .duration(50)
            .style("opacity", 1);
        tooltipDiv.html("node " + dNameForTooltip);

        g_path.on('mouseover', function (d, i) {
            d3.select(this).transition()
                .duration('50')
                .attr('opacity', '.85');
            //Makes the new div appear on hover:
            tooltipDiv.transition()
                .duration(50)
                .style("opacity", 1);
            let num = (Math.round((thisData[i].itemValue / 1) * 100)).toString() + '%';
            tooltipDiv.html("node " + dNameForTooltip + "<br>" + thisData[i].itemLabel + "<br>" + num);
        })
        .on('mouseout', function (d, i) {
            d3.select(this).transition()
                .duration('50')
                .attr('opacity', '1');
            tooltipDiv.html("node " + dNameForTooltip);
        });
    }

    if (nodeElement) {
        g_pie.append("path")
            .attr("fill", "lightsteelblue")
            .attr("d", arcBorder);
    }
}

// ***************** BUTTONS *********************

// Handler for dropdown value change
var dropdownChange = function() {
    // retrieve data from hash
    var treeType = d3.select("#tree-type").property('value'),
        treeRelease = d3.select("#tree-release").property('value');

    data = trees[treeRelease][treeType];

    // Assigns parent, children, height, depth
    root = d3.hierarchy(data, function(d) { return d.children; });

    taxa = [];
    genera = [];

    root.each( function(d) {
        if (d.data.name.match(/^[A-Z][a-z]+\s[a-z]+$/)) {
            taxa.push(d.data.name);
        } else if (d.data.name.match(/^[A-Z][a-z]+$/)) {
            genera.push(d.data.name);
        }
    });

    // get tree-species select and remove from view
    var treeSpeciesSelect = document.getElementById("tree-species");
    d3.select(treeSpeciesSelect.parentElement).remove();

    // get tree-genus select and remove from view
    var treeGenusSelect = document.getElementById("tree-genera");
    d3.select(treeGenusSelect.parentElement).remove();

    // get tree-species select and remove from view
    var backToRootButton = document.getElementById("back-to-root");
    d3.select(backToRootButton).remove();

    // create new tree-species select and back to root button
    createSearchSelect(taxa, genera);

    deleteTreeNodes();

    collapseAfterFourthLevel(root);
    update(root);
    addLegend();
    d3.select(".trait-rec-pie-zoom").select("svg").remove();
    d3.select(".trait-rec-pie-zoom").select("div").style("opacity", 0);
};

function createSelects(id, theseOptions) {
    var dropdown = d3.select(".js-button")
        .append("select", "svg")
        .attr("class", "selectpicker")
        .attr("id", id)
        .on("change", dropdownChange);

    dropdown.selectAll("option")
        .data(theseOptions)
        .enter().append("option")
        .attr("value", function (d) { return d; })
        .text(function (d) {
            return d[0].toUpperCase() + d.slice(1,d.length); // capitalize 1st letter
        });

    $(".selectpicker").selectpicker();
}

createSelects("tree-type", ["nuclear", "plastid"]);
createSelects("tree-release", Object.keys(trees).sort());
createSelects("tree-trait", ["lifespan", "lifestyle"]);

var determineTree = function() {
    var treeType = d3.select("#tree-type").property('value'),
        treeRelease = d3.select("#tree-release").property('value'),
        treeTrait = d3.select("#tree-trait").property('value');

    data = trees[treeRelease][treeType];

    root = d3.hierarchy(data, function(d) { return d.children; });
    return root;
};

var searchSpecies = function() {
    var species = d3.select(this).property('value');

    if (species === "Nothing selected") {
        backToRoot();
    } else {
        root = determineTree();

        var parentAsRoot;

        root.leaves().forEach( function(d) {
            if (d.data.name === species) {
                jumps = [];
                if (d.parent) {
                    if (d.parent.parent) {
                        if (d.parent.parent.parent) {
                            parentAsRoot = d.parent.parent.parent.copy();
                        } else {
                            parentAsRoot = d.parent.parent.copy();
                        }
                    } else {
                        parentAsRoot = d.parent.copy();
                    }
                }
            }
        });

        $("#tree-genera").val("");
        $(".selectpicker").selectpicker("refresh");

        deleteTreeNodes();

        collapseAfterFourthLevel(parentAsRoot);
        update(parentAsRoot);
    }
};

var searchGenus = function() {
  var genus = d3.select(this).property('value');

    if (genus === "Nothing selected") {
        backToRoot();
    } else {
        root = determineTree();

        var parentAsRoot;

        root.each( function(d) {
            if (d.data.name === genus) {
                jumps = [];
                parentAsRoot = d.copy();
            }
        });

        $("#tree-species").val("");
        $(".selectpicker").selectpicker("refresh");

        deleteTreeNodes();

        collapseAfterFourthLevel(parentAsRoot);
        update(parentAsRoot);
    }
};

var backToRoot = function() {
    root = determineTree();

    $("#tree-species").val("");
    $("#tree-genera").val("");
    $(".selectpicker").selectpicker("refresh");

    deleteTreeNodes();
    collapseAfterFourthLevel(root);
    update(root);
};

function createSearchSelect(taxaData, generaData) {
    var newTaxaData = taxaData.sort();
    var newGenera = generaData.sort();

    var dropdown = d3.select(".js-button")
        .append("select", "svg")
        .attr("class", "selectpicker")
        .attr("id", "tree-species")
        .attr("data-live-search", "true")
        .on("change", searchSpecies);

    dropdown.selectAll("option")
        .data(newTaxaData)
        .enter().append("option")
        .attr("value", function (d) { return d; })
        .text(function (d) {
            return d[0].toUpperCase() + d.slice(1,d.length); // capitalize 1st letter
        });

    $("#tree-species").val("");
    $(".selectpicker").selectpicker();

    var dropdown = d3.select(".js-button")
        .append("select", "svg")
        .attr("class", "selectpicker")
        .attr("id", "tree-genera")
        .attr("data-live-search", "true")
        .on("change", searchGenus);

    dropdown.selectAll("option")
        .data(newGenera)
        .enter().append("option")
        .attr("value", function (d) { return d; })
        .text(function (d) {
            return d[0].toUpperCase() + d.slice(1,d.length); // capitalize 1st letter
        });

    $("#tree-genera").val("");
    $(".selectpicker").selectpicker();

    var button = d3.select(".js-button")
        .append("button", "svg")
        .attr("class", "btn")
        .attr("id", "back-to-root")
        .text("Go back to root")
        .style("text-align", "left")
        .on("click", backToRoot);
}

// ***** initial setup of tree ***** //

svg = d3.select(".js-container").append("svg")
    .attr("width", width + margin.right + margin.left)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate("
        + margin.left + "," + margin.top + ")");

// Assigns parent, children, height, depth
var data = trees[Object.keys(trees)[0]]["nuclear"];
root = d3.hierarchy(data, function(d) { return d.children; });
root.x0 = height / 2;
root.y0 = 0;

root.each( function(d) {
    if (d.data.name.match(/^[A-Z][a-z]+\s[a-z]+$/)) {
        taxa.push(d.data.name);
    } else if (d.data.name.match(/^[A-Z][a-z]+$/)) {
        genera.push(d.data.name);
    }
});

createSearchSelect(taxa, genera);

collapseAfterFourthLevel(root);
update(root);

d3.selectAll(".dropdown-toggle")
    .attr("data-display", "static");

d3.selectAll("div.dropdown-menu")
    .attr("class", "dropdown-menu dropdown-menu-right");

function  addLegend() {
    d3.select(".trait-rec-legend").select("svg").remove();
    var legendContainer = d3.select(".trait-rec-legend").append("svg");

    var treeType = d3.select("#tree-trait").property('value');

    if (treeType == "lifespan") {
        var keys = ["annual", "biennial", "perennial"]
    } else if (treeType == "lifestyle") {
        var keys = ["autotroph", "facultative", "obligate", "holoparasitic"]
    }

    var colorRange = colorSelection[treeType];

    var color = d3.scaleOrdinal()
        .domain(keys)
        .range(colorRange);

    // Add one dot in the legend for each name.
    legendContainer.selectAll("mydots")
        .data(keys)
        .enter()
        .append("circle")
        .attr("cx", 20)
        .attr("cy", function(d,i){ return 12 + i*25}) // 100 is where the first dot appears. 25 is the distance between dots
        .attr("r", 7)
        .style("fill", function(d){ return color(d)});

    // Add one dot in the legend for each name.
    legendContainer.selectAll("mylabels")
        .data(keys)
        .enter()
        .append("text")
        .attr("x", 35)
        .attr("y", function(d,i){ return 12 + i*27.5}) // 100 is where the first dot appears. 25 is the distance between dots
        .style("fill", function(d){ return color(d)})
        .text(function(d){ return d})
        .attr("text-anchor", "left")
        .style("alignment-baseline", "middle");
}

addLegend();