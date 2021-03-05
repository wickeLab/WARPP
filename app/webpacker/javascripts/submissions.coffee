$ ->
  $('#submissions-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: $('#submissions-datatable').data('source'),
      data: { authenticity_token: $('[name="csrf-token"]')[0].content},
      type: 'POST'
    order: [[ 0, "desc" ]],
    pagingType: 'full_numbers'
    columns: [
      {data: 'submission'}
      {data: 'request'}
      {data: 'species'}
      {data: 'user'}
      {data: 'submitted'}
      {data: 'actions'}
    ]
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.