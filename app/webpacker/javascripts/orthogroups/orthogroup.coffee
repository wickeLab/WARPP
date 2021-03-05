# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

findNode = () ->
  nodeToFind = this.textContent.replace('_', ' ')

  temporaryRoot = d3.hierarchy(treeJSON, (d) -> return d.children)

  temporaryRoot.each (node) ->
    if node.data.name.includes(nodeToFind)
      click(node)
      return

window.showDetails = (member, taxon) ->
  id = member['ncbi_accession']
  locus_tag = member['cds_locus']
  definition = member['definition']

  d3.select(".node-detail-list").remove()

  nodeDetailParent = d3.select("#node-details").append('ul').attr("class", 'list-group list-group-flush node-detail-list')

  ncbi_accession = nodeDetailParent.append('li').attr("class", 'list-group-item')
  ncbi_accession.append('p').append('b').attr("class", "card-title").text('NCBI accession:')
  ncbi_accession.append('p').text(id)

  full_definition = nodeDetailParent.append('li').attr("class", 'list-group-item')
  full_definition.append('p').append('b').attr("class", "card-title").text('Full definition:')
  full_definition.append('p').text(definition)

  if (locus_tag)
    cds_locus = nodeDetailParent.append('li').attr("class", 'list-group-item')
    cds_locus.append('p').append('b').attr("class", "card-title").text('CDS locus tag:')
    cds_locus.append('p').append("a")
      .attr("href", "/genome_browser/jbrowse?taxon=#{taxon}&locus=#{locus_tag}")
      .text(locus_tag)

addTableContent = (member, taxon, parentElement) ->
  id = member['ncbi_accession']

  trParent = parentElement.append("tr")
  tdParent = trParent.append("td")
  tdLink = tdParent.append("button")
    .attr("class", "taxonomicAccordionLink")
    .attr("id", id)
    .text(id)
    .on("click", findNode)
  document.getElementById(id).onmouseover = ->
    showDetails(member, taxon)
    return

addAccordionCard = (taxon, members) ->
  taxonGsubbed = taxon.replace(" ", "-")

  accordionCard = parentContainer.append('div')
    .attr('class', 'card')
  cardHeader = accordionCard.append('div')
    .attr('class', 'card-header')
    .attr('id', "heading-#{taxonGsubbed}")
  cardButton = cardHeader.append('button')
    .attr('class', 'btn btn-link collapsed')
    .attr('type', 'button')
    .attr('data-toggle', 'collapse')
    .attr('data-target', "#collapse-#{taxonGsubbed}")
    .attr('aria-expanded', 'false')
    .attr('aria-controls', "collapse-#{taxonGsubbed}")
  cardButton.html '<i class="fa fa-plus"></i>' + taxon
  cardCollapse = accordionCard.append('div')
    .attr('id', "collapse-#{taxonGsubbed}")
    .attr('class', 'collapse')
    .attr('aria-labelledby', "heading-#{taxonGsubbed}")
  cardBody = cardCollapse.append('div')
    .attr('class', 'card-body')
  tableParent = cardBody.append('table')
  tableBody = tableParent.append('tbody')
  members.forEach (member) ->
    addTableContent member, taxon, tableBody

$ ->
  $(document).on('show.bs.collapse', '.collapse', ->
    $(this).prev('.card-header').find('.fa').removeClass('fa-plus').addClass 'fa-minus'
    return
  ).on('hide.bs.collapse', '.collapse', ->
    $(this).prev('.card-header').find('.fa').removeClass('fa-minus').addClass 'fa-plus'
    return
  )
  return

taxonFunctions = JSON.parse(gon.taxon_functions)
parentContainer = d3.select(".accordion#taxon-functions")

addTaxon = (item, index) ->
  taxon = item['taxon']
  members = item['children']
  addAccordionCard(taxon, members)

taxonFunctions.forEach addTaxon