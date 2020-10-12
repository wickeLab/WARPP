var treeJSON = JSON.parse(gon.orthogroup_tree);

//globals
var depth = 0;

// Set the dimensions and margins of the diagram
var margin = {top: 20, right: 40, bottom: 30, left: 40},
    width = 750 - margin.left - margin.right,
    height = 485 - margin.top - margin.bottom;

var i = 0,
    duration = 600,
    root,
    svg;

// declares a tree layout and assigns the size
var treemap = d3.tree()
    .size([height, width])
    .nodeSize([40, 40]);

var jumps = [];

function collapseAfterNthLevel(source, level) {
    source.children.forEach( function(d) {
        if (d.children) {
            if (d.depth === level - 1) {
                collapse(d)
            } else {
                collapseAfterNthLevel(d, level)
            }
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

// Expand the node
function expand(d) {
    if (d._children) {
        d.children = d._children;
        d._children = null
    }
    if (d.children) {
        d.children.forEach(expand);
    }
}

function searchDetails(nodeName) {
    JSON.parse(gon.taxon_functions).forEach(function (entry) {
        if (nodeName.includes(entry['taxon'])) {
            entry['children'].forEach(function (child) {
                if (nodeName.includes(child['ncbi_accession'].replace('_', ' '))) {
                    showDetails(child, entry['taxon']);
                }
            })
        }
    })
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

// Define the div for the tooltip
var hoverDiv = d3.select(".d3-container").append("div")
    .attr("class", "full-node-name")
    .style("opacity", 0);

function update(source) {
    p.call(zoom.transform, transform);

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
        //.attr('id', function(d) {
        //return "node-" + d.data.name.replace(/\./g, '_').replace(/\s/g, '_');
        //})
        .attr("transform", function(d) {
            return "translate(" + source.y0 + "," + source.x0 + ")";
        })
        .on('click', click)
        .on("mouseover", function(d) {
            searchDetails(d.data.name);
            hoverDiv.transition()
                .duration(200)
                .style("opacity", 1);
            hoverDiv.html(d.data.name)
                .style("left", (d3.event.pageX) + "px")
                .style("top", (d3.event.pageY - 50) + "px");

            if (!d.children && d._children) {
                var temporaryRoot = d3.hierarchy(treeJSON, function(d) { return d.children; });
                var dId = d.data.id;

                temporaryRoot.each( function(d) {
                    if (d.data.id === dId) {
                        var temporarySubTree =  d.copy();
                        var hiddenTaxa = temporarySubTree.leaves().map (function(d) {
                            if (d.data.name !== "") {
                                return d.data.name;
                            }
                        });

                        var hiddenTaxaList = hiddenTaxa.sort();

                        showTooltip(hiddenTaxaList);
                        return false;
                    }
                });
            }
        })
        .on("mouseout", function() {
            hoverDiv.transition()
                .duration(500)
                .style("opacity", 0);
        });

    // Add labels for the nodes
    nodeEnter.append('text')
        .attr("dy", ".35em")
        .attr("x", function(d) {
            return d.depth === 0 ? -10 : 10;
        })
        .attr("y", function(d) {
            return d.depth > 0 && (d.children || d._children) ? -7 : 0;
        })
        .attr("text-anchor", function(d) {
            return d.children || d._children ? "end" : "start";
        })
        .text(function(d) {
            if (d.data.id === rootNodeId) {
                return "root";
            } else if (d.data.name === "" || d.data.name.includes("internal node")) {
                return "";
            } else if (d.data.more === true) {
                return "click to load subtree";
            } else {
                return d.data.name.match(/[A-Z]{2}\s[\d.]+/)[0];
                // return d.data.name.match(/[A-Z][a-z\s]+/)[0];
            }
        });

    // Add Circle for the nodes
    nodeEnter.append('circle')
        .attr('class', 'node')
        .attr('r', 1e-6)
        .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
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

    // Update the node attributes and style
    nodeUpdate.select('circle.node')
        .attr('r', 3)
        .style("fill", function(d) {
            return d._children ? "lightsteelblue" : "#fff";
        })
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
}

function getAncestorAtNthLevel(currentRoot, level) {
    var parentNode = currentRoot.parent;
    if (parentNode.depth === level || !parentNode.parent) {
        return parentNode
    } else {
        return getAncestorAtNthLevel(parentNode, level)
    }
}

// Toggle children on click.
function click(d) {
    if (d.depth === 0) {
        root = d3.hierarchy(treeJSON, function (d) { return d.children; });

        let newRoot;

        root.each(function (node) {
            if (node.data.id === d.data.id) {
                if (jumps.length > 0) {
                    newRoot = getAncestorAtNthLevel(node, node.depth - jumps[jumps.length - 1]);
                    jumps.pop();
                } else {
                    newRoot = getAncestorAtNthLevel(node, node.depth - 9);
                }
                return
            }
        });

        root = newRoot.copy();
    } else if (d._children) {
        d.children = d._children;
        d.children.forEach(expand);
        root = d.copy();
        jumps.push(d.depth);
    } else if (d.children) {
        d.children.forEach(expand);
        root = d.copy();
        jumps.push(d.depth);
    } else {
        let newRoot = getAncestorAtNthLevel(d, d.depth - 9);
        root = newRoot.copy();
        jumps = [];
    }

    deleteTreeNodes();

    collapseAfterNthLevel(root, 10);
    update(root);
}

function deleteTreeNodes() {
    d3.select(".js-container").selectAll(".node").remove();
}

var backToRoot = function() {
    var root = d3.hierarchy(treeJSON, function (d) { return d.children; });

    deleteTreeNodes();
    collapseAfterNthLevel(root, 10);
    update(root);
};

// ***** initial setup of tree ***** //

// create zoom
var zoom = d3.zoom().on("zoom", function() {
    svg.attr("transform", d3.event.transform);
});

var el = document.getElementById('width-reference');
var svgBox = el.getBoundingClientRect();
var actualWidth = window.innerWidth - svgBox.width,
    actualHeight = window.innerHeight;

d3.select(".fix-position-wrapper").style("width", `${actualWidth}px`);
d3.select(".d3-container").style("width", `${actualWidth}px`);

// append the svg object to the body of the page
p = d3.select(".d3-container").append("svg")
    .attr("width", "100%")
    .attr("height", "100%")
    .call(zoom);

// Set up the initial identity:
var transform = d3.zoomIdentity;
transform.x = actualWidth/3;
transform.y = actualHeight/3;
transform.k = 1;

svg = p.append("g")
    .attr("class", "view");

p.call(zoom.transform, transform);

// Assigns parent, children, height, depth
root = d3.hierarchy(treeJSON, function(d) { return d.children; });
root.x0 = height / 2;
root.y0 = 0;

var rootNodeId = root.data.id;

collapseAfterNthLevel(root, 10);

update(root);

var button = d3.select(".downloads")
    .append("button", "svg")
    .attr("class", "btn")
    .attr("id", "back-to-root")
    .text("Go back to root")
    .on("click", backToRoot);
