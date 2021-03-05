allOrthoTaxa = JSON.parse(gon.all_ortho_taxa)

chapterNavigation = d3.select('.chapter-navigation')
firstOrderUl = chapterNavigation.append('ul').attr('class', 0)

headings = document.querySelectorAll('h2, h3, h4, h5')

h1 = document.querySelector('h1')
firstOrderLi = firstOrderUl.append('li').html("<a href='##{h1.innerHTML.replace(/\s/g, '-')}'>#{h1.innerHTML}</a>").attr('onclick', "$event.preventDefault()")
h1.id = h1.innerHTML.replace(/\s/g, '-')

Uls = [firstOrderUl]
Lis = [firstOrderLi]
lastLevel = 0

i = 0
while i < headings.length
  heading = headings[i]
  heading.id = heading.innerHTML.replace(/\s/g, '-')
  level = parseInt(heading.tagName.match(/\d/)[0])

  if level > lastLevel # child, append sublist
    newUl = Lis[Lis.length - 1].append('ul')
    Uls.push(newUl)
  else if level < lastLevel
    Uls.pop()

  newLi = Uls[Uls.length - 1].append('li').html("<a href='##{heading.innerHTML.replace(/\s/g, '-')}'>#{heading.innerHTML}</a>").attr('onclick', "$event.preventDefault()")
  Lis.push(newLi)
  lastLevel = level

  i++

orthoSection = document.getElementById("Orthogroups").nextSibling.nextSibling
orthoAccordion = document.createElement("div")
orthoAccordion.id = "ortho-accordion"
orthoAccordion.className = "card"
orthoSection.parentNode.insertBefore(orthoAccordion, orthoSection.nextSibling)

orthoAccordion = d3.select('#ortho-accordion')
cardHeader = orthoAccordion.append("div")
  .attr("class", "card-header")
  .attr("id", "heading-ortho")
cardButton = cardHeader.append("button")
  .attr("class", "btn btn-link collapsed")
  .attr("type", "button")
  .attr("data-toggle", "collapse")
  .attr("data-target", "#collapse-ortho")
  .attr("aria-expanded", "false")
  .attr("aria-controls", "collapse-ortho")

cardButton.html('<h6><small><i class="fas fa-chevron-right"></i></small> Species included in the <a href="/orthogroups">orthogroup table</a></h6>')

cardCollapse = orthoAccordion.append("div")
  .attr("id", "collapse-ortho")
  .attr("class", "collapse")
  .attr("aria-labelledby", "heading-ortho")

cardBody = cardCollapse.append("div")
  .attr("class", "card-body")
cardUl = cardBody.append("ul")

allOrthoTaxa.forEach (taxon) ->
  taxonLi = cardUl.append("li").append("a")
    .attr("id", taxon)
    .attr("class", "taxonLink")
    .attr("href", "/taxa/search/#{taxon}")
    .text(taxon)


$(document).on('show.bs.collapse', '.collapse', ->
  $('#heading-ortho').find('.fas').removeClass('fa-chevron-right').addClass('fa-chevron-down')
  return
).on('hide.bs.collapse', '.collapse', ->
  $('#heading-ortho').find('.fas').removeClass('fa-chevron-down').addClass('fa-chevron-right')
  return
)