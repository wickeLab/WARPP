# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#ppg-queries-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: $('#ppg-queries-datatable').data('source'),
      type: 'POST'
    order: [[ 0, "asc" ]],
    pagingType: 'full_numbers'
    scrollX: true
    columns: [
      {data: 'query_name'}
      {data: 'functional_assignment'}
      {data: 'median_functionality_score'}
    ]