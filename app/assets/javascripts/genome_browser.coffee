# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$("#genomes").selectpicker("refresh")

window.getGenomeBrowser = () ->
  taxon = $("#genomes option:selected").val().replace(" ", "_").toLowerCase()
  window.location.href = "/genome_browser/jbrowse?taxon=#{taxon}"