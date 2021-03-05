# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#server-jobs-datatable').DataTable
    dom: 'lrtp'
    processing: true
    serverSide: true
    ajax:
      url: $('#server-jobs-datatable').data('source'),
      data: { authenticity_token: $('[name="csrf-token"]')[0].content},
      type: 'POST'
    order: [[ 2, "desc" ]],
    pagingType: 'full_numbers'
    columns: [
      {data: 'job_type', className: 'select-filter'}
      {data: 'job_title'}
      {data: 'submitted'}
      {data: null, render: 'status'}
    ]
    initComplete: ->
      column = @api().columns('.select-filter')
      select = $('<select id="server-job-select"><option value="">Select all</option></select>').appendTo($(column.header())).on('change', ->
        column.search($(this).val()).draw()
        return
      )
      job_types = []
      job_types.push val for val in column.data()['0'] when val not in job_types

      job_types.sort().forEach (d) ->
        select.append "<option value='#{d}'>" + d + '</option>'
        return
      return