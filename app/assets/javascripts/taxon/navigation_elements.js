function toggleSidebar() {
    if (document.getElementById("width-reference").getBoundingClientRect().width == 0) {
        d3.select("#width-reference").style("display", "flex");
        document.getElementById('width-reference').style.width=("auto");
    } else {
        d3.select("#width-reference").style("display", "none");
        document.getElementById('width-reference').style.width=("0");
    }
}

function recenterTree() {
    el = document.getElementById('tree-container');
    treeContainer = el.getBoundingClientRect();
    actualWidth = treeContainer.width;
    actualHeight = window.innerHeight;

    d3.select(".d3-container").style("width", `${actualWidth}px`);
    d3.select("#taxonomy-tree-svg").attr("viewBox", "0 0 " + actualWidth + " " + actualHeight);

    let treeBox = document.getElementById('tree-view').getBoundingClientRect();
    let treeWidth = treeBox.width;

    // Set up the initial identity:
    transform.x = actualWidth/2;
    transform.y = actualHeight/2;
    if (treeWidth > actualWidth) {
        transform.k =  actualWidth / treeWidth - 0.15 ;
    } else {
        transform.k = 1;
    }

    // apply transform to g by acting on svg
    p.call(zoom.transform, transform);
}

d3.select("#retract-info")
    .on("click", toggleSidebar);

d3.select("#reset-tree")
    .on("click", recenterTree);

var ro = new ResizeObserver(entries => {
    for (let entry of entries) {
        recenterTree();
    }
});

ro.observe(document.getElementById('tree-container'));

