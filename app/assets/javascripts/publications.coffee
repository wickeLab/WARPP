# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#publications-datatable').dataTable
    responsive: true
    processing: true
    serverSide: true
    ajax:
      url: $('#publications-datatable').data('source'),
      type: 'POST'
    order: [[ 0, "desc" ]],
    pagingType: 'full_numbers'
    columns: [
      {data: 'year'}
      {data: 'authors'}
      {data: 'title'}
      {data: 'species'}
    ]
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.

toggleRSSFeed = () ->
  if (document.getElementById("feed-container").getBoundingClientRect().width == 45)
    document.getElementById('feed-container').style.width=("450px")

    d3.select(".rss-feed")
      .style("border-left", "2px solid #e0e0e0")

  else
    document.getElementById('feed-container').style.width=("45px")
    d3.select(".rss-feed")
      .style("border-left", "none")

d3.select(".button-container").append("button", "svg")
  .attr("type", "submit")
  .attr("class", "btn")
  .attr("id", "toggle-filter-options")
  .on("click", toggleRSSFeed)
  .attr("title", "Toggle RSS feed")
  .html('<i class="fas fa-rss"></i>');