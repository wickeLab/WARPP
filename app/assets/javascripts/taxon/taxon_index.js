//= require ./d3_tree
//= require ./navigation_elements
//= require ./filter_index
//= require ./orobanchaceae_accordion

window.addEventListener('resize', recenterTree);

document.addEventListener("DOMContentLoaded", function() {
    el = document.getElementById('tree-container');
    treeContainer = el.getBoundingClientRect();
    actualWidth = treeContainer.width;
    actualHeight = window.innerHeight;

    p.attr("viewBox", "0 0 " + actualWidth + " " + actualHeight);
    recenterTree();
});
