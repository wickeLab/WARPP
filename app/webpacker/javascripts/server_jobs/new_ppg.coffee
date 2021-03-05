submission = document.getElementById("mail-notifier")

window.mailNotify = () ->
  checkBox = document.getElementById("myCheck")

  if checkBox.checked
    submission.style.display = 'block'
  else
    submission.style.display = 'none'

window.clearText = () ->
  element = document.getElementById("textarea-seqs")
  element.value = ''

$("#ppg_job_stringency").selectpicker("refresh")

document.querySelector('#fasta-upload').addEventListener 'change', (e) ->
  files = e.target.files
  fileList = $('#uploaded-files')
  fileList.empty()
  fileList.append "<tr><td><b>Your chosen files: #{files.length}</b></td></tr>"
  c = 0
  while c < files.length
    fileList.append "<tr><td>#{files[c].name}</td></tr>"
    c++
  return