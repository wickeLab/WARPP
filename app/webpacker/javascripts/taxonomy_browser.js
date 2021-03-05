import "./taxonomy_browser/d3_tree"
import "./taxonomy_browser/orobanchaceae_accordion"
import "./taxonomy_browser/navigation_elements"
import "./taxonomy_browser/filter_index"

import { recenterTree } from "./taxonomy_browser/navigation_elements"

window.addEventListener('resize', recenterTree);

document.addEventListener("DOMContentLoaded", function() {
    let el = document.getElementById('tree-container');
    let treeContainer = el.getBoundingClientRect();
    let actualWidth = treeContainer.width;
    let actualHeight = window.innerHeight;

    let p = d3.select("#taxonomy-tree-svg")
    p.attr("viewBox", "0 0 " + actualWidth + " " + actualHeight);
    recenterTree();
});
