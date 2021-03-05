userTargets = gon.user_targets

columns = [
  {data: 'query_name'}
  {data: 'functional_assignment'}
  {data: 'median_functionality_score', className: 'median'}
]

userTargets.forEach (target) ->
  column_info = {data: null, render: target, className: 'functionality'}
  columns.push(column_info)
  return

$ ->
  if document.getElementById('ppg-relaxed-matches-datatable')
    $('#ppg-relaxed-matches-datatable').DataTable
      searching: false
      ordering: false
      scollCollapse: true
      scrollX: true
      ###
      fixedColumns: {
        leftColumns: 3
      }
      ###
      processing: true
      serverSide: true
      ajax:
        url: $('#ppg-relaxed-matches-datatable').data('source'),
        type: 'POST'
      order: [[ 0, "asc" ]],
      pagingType: 'full_numbers'
      columns: columns
      drawCallback: ->
        styleTable(document.getElementById('ppg-relaxed-matches-datatable'))

  if document.getElementById('ppg-stringent-matches-datatable')
    $('#ppg-stringent-matches-datatable').DataTable
      searching: false
      ordering: false
      scollCollapse: true
      scrollX: true
      processing: true
      serverSide: true
      ajax:
        url: $('#ppg-stringent-matches-datatable').data('source'),
        type: 'POST'
      order: [[ 0, "asc" ]],
      pagingType: 'full_numbers'
      columns: columns
      drawCallback: ->
        styleTable(document.getElementById('ppg-stringent-matches-datatable'))

styleTable = (t) ->
  r = 0
  while r < t.rows.length
    c = 0
    while c < t.rows[r].cells.length
      thisCell = t.rows[r].cells[c]
      score = thisCell.innerHTML
      if score.match(/<li>/)
        score = score.match(/\d\.\d+/)[0]

      if !isNaN(score) && score != ''
        thisCell.style.backgroundColor = 'rgba(' + 79 + ',' + 99 + ',' + 103 + ',' + score + ')'
        if Number(score) > 0.5
          thisCell.style.color = "white"
      c++
    r++