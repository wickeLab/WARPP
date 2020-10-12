# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

allTaxa = JSON.parse(gon.all_taxa)

columns = [
  {data: 'orthogroup'}
  {data: 'function_realm', className: 'function-realm'}
]

allTaxa.forEach (taxon) ->
  column_info = if taxon == "Arabidopsis thaliana"
    {data: taxon, className: 'a-thaliana'}
  else
    {data: null, render: taxon}
  columns.push(column_info)

$ ->
  table = $('#orthogroups-datatable').dataTable
    processing: true
    serverSide: true
    oLanguage: {
      sSearch: "Search <small>(functional assignment, locus, NCBI accession)</small>"
    }
    ajax:
      url: $('#orthogroups-datatable').data('source')
      type: 'POST'
    order: [[ 0, "asc" ]]
    pagingType: 'full_numbers'
    columns: columns
    searchDelay: 1500

# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.

addViewport = ->
  document.querySelector(".dataTable").closest(".col-sm-12").classList.add('orthogroup-viewpoint')

setupOrthogroupDragscroll = ->
  new ScrollBooster(
    viewport: document.querySelector(".orthogroup-viewpoint")
    content: document.querySelector(".dataTable")
    direction: 'horizontal'
    scrollMode: 'native')
  return

datatableSetup = ->
  addViewport()
  setupOrthogroupDragscroll()

wait = ->
  if document.querySelector(".dataTable").closest(".col-sm-12") == null
    setTimeout wait, 500
  else
    datatableSetup()
  return

wait()