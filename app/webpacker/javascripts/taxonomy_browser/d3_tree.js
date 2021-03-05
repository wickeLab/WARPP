//TODO text position in tree (clades especially) <- improve
var newData = JSON.parse(gon.all_oros);
var informationScore = JSON.parse(gon.information_score);
var maxDepth = parseInt(gon.max_depth);

// create zoom
export var zoom = d3.zoom().on("zoom", function() {
    svg.attr("transform", d3.event.transform);
});

var el = document.getElementById('tree-container');
let treeContainer = el.getBoundingClientRect();
var actualWidth = treeContainer.width,
    actualHeight = window.innerHeight;

// create svg apply zoom to it
var p = d3.select(".d3-container").append("svg")
    .attr("id", "taxonomy-tree-svg")
    .attr("width", "100%")
    .attr("height", "100%")
    .call(zoom);

d3.select(".d3-container").style("width", `${actualWidth}px`);

// Set up the initial identity:
export const transform = d3.zoomIdentity;

// create g, store as svg, so I don't have to refactor code later
var svg = p
    .append("g")
    .attr("class", "view")
    .attr("id", "tree-view");

var i = 0,
    duration = 750;

export var root;

// declares a tree layout and assigns size
var cluster = d3.cluster()
    .size([360, actualWidth * 0.63]);

// Assigns parent, children, height, depth
root = d3.hierarchy(newData, function(d) { return d.children; });
root.x0 = 0;
root.y0 = 0;

var numberOfLeaves = root.leaves().length,
    numberOfSecondLevelNodes = root.children.length;

var nodeSize;

if (numberOfSecondLevelNodes <= 50) {
    nodeSize = 4;
} else if (numberOfSecondLevelNodes <= 100) {
    nodeSize = 3;
} else if (numberOfSecondLevelNodes <= 200) {
    nodeSize = 2;
} else {
    nodeSize = 1;
}

cluster.nodeSize([nodeSize, 40]);

function collapseAfterNthLevel(source, level) {
    source.children.forEach( function(d) {
        if (d.depth === level - 1) {
            collapse(d)
        } else {
            collapseAfterNthLevel(d, level)
        }
    });
}

if (!(maxDepth === 2 && numberOfLeaves < 100)) {
    collapseAfterNthLevel(root, maxDepth);
}
update(root);

// Collapse the node and all it's children
function collapse(d) {
    if(d.children) {
        d._children = d.children;
        d._children.forEach(collapse);
        d.children = null
    }
}

// code is based on d3noob's collapsible tree diagram in v4
// https://bl.ocks.org/d3noob/43a860bc0024792f8803bba8ca0d5ecd
export function update(source) {
    // Assigns the x and y position for the nodes
    var treeData = cluster(root);

    // Compute the new tree layout.
    var nodes = treeData.descendants(),
        links = treeData.descendants().slice(1);

    // Normalize for fixed-depth.
    nodes.forEach( function(d) {
        if (numberOfSecondLevelNodes <= 50) {
            d.y = d.depth * 270
        } else if (numberOfSecondLevelNodes <= 100) {
            d.y = d.depth * 360
        } else if (numberOfSecondLevelNodes <= 200) {
            d.y = d.depth * 450
        } else {
            d.y = d.depth * 540
        }
    });

    // Update the nodes...
    var node = svg.selectAll('g.node')
        .data(nodes, function(d) {return d.id || (d.id = ++i); });

    // Enter any new modes at the parent's previous position.
    var nodeEnter = node.enter().append('g')
        .attr('class', 'node')
        .attr("transform", function(d) {
            return "translate(" + project(source.x0, source.y0) + ")";
        })
        .on('click', click);

    // Add circle for the nodes
    nodeEnter.append('circle')
        .attr('class', 'node')
        .attr('r', 1e-6)
        .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
        });

    // Add labels for the nodes
    var nodeText = nodeEnter.append('text')
        .attr("dy", ".35em")
        .attr("x", function(d) {
            return d.x < 0 ? -6 : 6;
        })
        .attr("text-anchor", function(d) {
            return d.x < 0 ? "end" : "start";
        })
        .attr("transform", function(d) {
            if (d.x < 0) {
                return "rotate(" + (d.x - 270) + ")";
            } else {
                return "rotate(" + (d.x + 270) + ")";
            }
        })
        .style("font-weight", function(d) {
            if (d.depth === maxDepth - 1 && $(`\#collapse-${d.data.name}`).hasClass("show")) {
                return "bold";
            } else {
                return "normal";
            }
        })
        .text(function(d) { return d.data.name; })
        .on("mouseover", function(d) {
            if (d.depth === maxDepth - 1 && d._children){
                drawTooltipPie(d, "information_score", [customColors["gray"], customColors["meager"], customColors["decent"], customColors["good"]]);
                drawTooltipPie(d, "lifespan", [customColors["gray"], customColors["annual"], customColors["biennial"], customColors["perennial"]]);
                drawTooltipPie(d, "lifestyle", [customColors["gray"], customColors["autotroph"], customColors["facultative"], customColors["obligate"], customColors["holoparasitic"]]);
                drawTooltipPie(d, "habit", [customColors["gray"], customColors["autotroph"], customColors["facultative"]])
            }
        });

    var foreignObject = nodeEnter.append('foreignObject')
        .attr("transform", function(d) {
            return "translate(" + project(source.x0, source.y0) + ")";
        })
        .attr("transform", function(d) {
            return "rotate(" + (d.x - 125) + ")";
        })
        .attr("x", function(d) {
            return 65;
        })
        .attr("y", function(d) {
            return 40;
        })
        .attr("width", 100)
        .attr("height", 100);

    var div = foreignObject.append('xhtml:div')
        .attr("class", function(d) {
            return "d3-" + d.data.name;
        })
        .attr("width", 100 + "px")
        .attr("height", 100 + "px");

    // Update
    var nodeUpdate = nodeEnter.merge(node);

    // Transition to the proper position for the node
    nodeUpdate.transition()
        .duration(duration)
        .attr("transform", function(d) {
            return "translate(" + project(d.x, d.y) + ")";
        });

    // Update the node attributes and style
    nodeUpdate.select('circle.node')
        .attr('r', 3)
        .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
        })
        .attr('cursor', 'pointer');

    nodeUpdate.select("text")
        .attr("x", function(d) {
            return d.x < 0 ? -6 : 6;
        })
        .attr("text-anchor", function(d) {
            return d.x < 0 ? "end" : "start";
        })
        .attr("transform", function(d) {
            if (d.x < 0) {
                return "rotate(" + (d.x - 270) + ")";
            } else {
                return "rotate(" + (d.x + 270) + ")";
            }
        })
        .style("font-weight", function(d) {
            if ($(`\#collapse-${d.data.name}`).hasClass("show")) {
                return "bold";
            } else {
                return "normal";
            }
        })
        .style("fill", function(d) {
            return d.depth < 2 || d._children ? "#343a40" : "#939393";
        });

    // Remove any exiting nodes
    var nodeExit = node.exit().transition()
        .duration(duration)
        .attr("transform", function(d) {
            return "translate(" + project(source.x, source.y) + ")";
        })
        .remove();

    // On exit reduce the node circles size to 0
    nodeExit.select('circle')
        .attr('r', 1e-6);

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
            return "M" + project(source.x, source.y)
                + "L" + project(source.x, source.y);
        });

    // Update
    var linkUpdate = linkEnter.merge(link);

    // Transition back to the parent element position
    linkUpdate.transition()
        .duration(duration)
        .attr("d", function(d) {
            return "M" + project(d.x, d.y)
                + "L" + project(d.parent.x, d.parent.y);
        });

    // Remove any exiting links
    var linkExit = link.exit().transition()
        .duration(duration)
        .attr('d', function(d) {
            return "M" + project(source.x, source.y)
                + "L" + project(source.x, source.y);
        })
        .remove();

    // Store the old positions for transition.
    nodes.forEach(function(d){
        d.x0 = d.x;
        d.y0 = d.y;
    });

    // Toggle children on click.
    function click(d) {
        if (d.depth === maxDepth - 1) {
            $(`\#collapse-${d.data.name}`).collapse("toggle");
            location.href = `\#heading-${d.data.name}`;
        }

        if (d.children) {
            d._children = d.children;
            d.children = null;
            update(d);
        } else if (d._children && (d.depth < maxDepth - 1 || numberOfLeaves < 100)) {
            d.children = d._children;
            d._children = null;
            update(d);
        }
    }
}

function project(x, y) {
    // Calculate angle, and adjust radius so that links are not too long
    var angle = (x - 90) / 180 * Math.PI, radius = y*0.75;
    return [radius * Math.cos(angle), radius * Math.sin(angle)];
}

export function changeTreeData(newData, pieChartData) {
    informationScore = pieChartData;
    root = d3.hierarchy(newData, function(d) { return d.children; });
    // collapse everything after third level
    root.children.forEach( function(d) {
        if (d.children) {
            d.children.forEach(collapse);
        }
    });

    d3.select(".d3-container").select("svg").selectAll(".node").remove();
    update(root);
    d3.select(".tooltip-container").remove(); //TODO update
}

d3.select(`#hide-filter-info`)
    .on("click", function(d) {
        d3.select(`#filter-info-field`).remove();
        d3.select('.speech-bubble').remove();
    });

function drawTooltipPie(d, information, colorRange) {
    d3.select(`.${information}-tree-container`).select(".traitRecPie").remove();
    d3.select(`.${information}-tree-container`).select(".tooltip-legend").remove();

    var dName = d.data.name,
        dataJSON = informationScore[dName][information],
        thisData = [];

    Object.entries(dataJSON).map(function([k, v]) {
        thisData.push({
            "itemLabel": k,
            "itemValue": v
        });
    });

    var width = 100,
        height = 100,
        radius = Math.min(width, height)/2 - 3,
        dataLabels = thisData.map(function(item) { return item.itemLabel; });

    var color = d3.scaleOrdinal()
        .domain(dataLabels)
        .range(colorRange);

    var arc = d3.arc()
        .outerRadius(radius)
        .innerRadius(0);

    var pie = d3.pie()
        .sort(null)
        .value(function(d) { return d.itemValue; });

    var tooltipDiv = d3.select(`.${information}-tree-container`);

    var svg_pie = tooltipDiv.append("svg")
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

    var tooltipDivLegend = tooltipDiv.append("div")
        .attr("class", "tooltip-legend")
        .style("opacity", 0);

    tooltipDivLegend.transition()
        .duration(50)
        .style("opacity", 1);
    tooltipDivLegend.html(dName);

    g_path.on('mouseover', function (d, i) {
        d3.select(this).transition()
            .duration('50')
            .attr('opacity', '.85');
        //Makes the new div appear on hover:
        tooltipDivLegend.transition()
            .duration(50)
            .style("opacity", 1);

        var allValues = thisData.map(function(item) {return item.itemValue;});
        var sum = allValues.reduce(function(a, b) {
           return a + b;
        }, 0);

        let num = (Math.round((thisData[i].itemValue / sum) * 100)).toString() + '%';
        tooltipDivLegend.html(dName + "<br>" + thisData[i].itemLabel + "<br>" + num);
    })
        .on('mouseout', function (d, i) {
            d3.select(this).transition()
                .duration('50')
                .attr('opacity', '1');
            tooltipDivLegend.html(dName);
        });
}


// ADD LEGEND
function addLegend(title, parentContainer, information) {
    let header = title.replace('_', "\n").toLowerCase().split("\n").map(word => word.charAt(0).toUpperCase() + word.substring(1)).join("\n");
    parentContainer.append("div").html('<b>' + header.replace('Score', 'Availability') + '</b>');

    Object.entries(information).map(function ([k,v]) {
        var legendContainer = parentContainer.append("svg").attr("viewBox", "0 0 120 20");
        legendContainer.append("circle").attr("cx", 12).attr("cy", 12).attr("r", 4).style("fill", v);
        legendContainer.append("text").attr("x", 20).attr("y", 15).text(k).style("font-size", "1rem").attr("alignment-baseline", "middle");
    });

    parentContainer.append("div")
        .attr("class", `${title}-tree-container`)
        .style("display", "flex")
        .style("flex-direction", "column")
        .style("height", "180px");
}

addLegend("information_score", d3.select("#information-score"), {"unknown": customColors["gray"], "meager": customColors["meager"], "decent": customColors["decent"], "good": customColors["good"]});
addLegend("lifespan", d3.select("#lifespan"), {"unknown": customColors["gray"], "annual": customColors["annual"], "biennial": customColors["biennial"], "perennial": customColors["perennial"]});
addLegend("lifestyle", d3.select("#lifestyle"), {"unknown": customColors["gray"], "autotroph": customColors["autotroph"], "facultative": customColors["facultative"], "obligate": customColors["obligate"], "holoparasitic": customColors["holoparasitic"]});
addLegend("habit", d3.select("#habit"), {"unknown": customColors["gray"], "herbaceous": customColors["autotroph"], "tree": customColors["tree"]});
