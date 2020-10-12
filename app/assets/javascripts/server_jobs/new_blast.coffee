# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

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

$('.selectpicker').selectpicker({
  size: '5',
  liveSearch: true
});
$(".selectpicker").selectpicker("refresh")

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