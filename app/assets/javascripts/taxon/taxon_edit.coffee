speciesId = gon.species_id
currentUser = gon.current_user

hosts = gon.hosts
parasites = gon.parasites

hostsToAdd = {}
parasitesToAdd = {}

hostsToDelete = []
parasitesToDelete = []

lifespanReferences = []
lifestyleReferences = []
habitReferences = []
chromosomeReferences = []
genomeReferences = []

doiPattern = /^\d{2}\.\d+\.?\d*\/.+$/i

hostContainer = d3.select("#hosts")
parasiteContainer = d3.select("#parasites")

# functions + buttons

deleteFromArray = (a, element) ->
  i = a.indexOf(element)
  a.splice(i, 1)
  a.splice(i, 1)

deleteRelation = (container, species, type, referenceArray, reference) ->
  container.remove()

  if type == "host"
    if species in hosts
      hostsToDelete.push(species)
    else
      delete hostsToAdd[species]
  else if type == "parasite"
    if species in parasites
      parasitesToDelete.push(parasite)
    else
      delete parasitesToAdd[species]
  else # reference
    deleteFromArray(referenceArray, reference)
    if habitReferences.length == 0
      d3.select("input#habit")
        .attr("readonly", null)
    if chromosomeReferences.length == 0
      d3.select("input#chromosome")
        .attr("readonly", null)
    if genomeReferences.length == 0
      d3.select("input#genome")
        .attr("readonly", null)

addRelation = (parentContainer, species, type) ->
  containerWrapper = parentContainer.append("div")
    .attr("class", "relation-wrapper")
    .attr("id", "#{species.replace(" ", "-").replace(".", "")}-wrapper")

  container = containerWrapper.append("div")
    .attr("class", "species-wrapper")

  container.append("text")
    .html(species)
    .style('color', (d) ->
      if species in hosts || species in parasites then '#343a40' else '#9ea369')

  button = container.append("button", "svg")
    .attr("class", "btn")
    .attr("type", "submit")
    .attr("id", "submit-relation")
    .on("click", -> deleteRelation(containerWrapper, species, type, undefined, undefined))

  button.append("i")
    .attr("class", "fas fa-backspace")

  referenceContainer = containerWrapper.append("div")
    .attr("class", "references-wrapper")
    .attr("id", "#{species.replace(" ", "-").replace(".", "")}-ref-wrapper")

checkAndProcessRelation = () ->
  species = $("#species").val()
  references = $("#reference-field").val().replace(" ", "").split(",")

  if !(species == "")
    if $("#relation-type").val() == "As host"
      if $("##{species.replace(" ", "-").replace(".", "")}-wrapper").length == 0
        addRelation(hostContainer, species, "host")
      if hostsToAdd[species] == undefined
        hostsToAdd[species] = []
      parentContainer = d3.select("##{species.replace(" ", "-").replace(".", "")}-ref-wrapper")
      addReference(parentContainer, references, hostsToAdd[species])
    else
      if $("##{species.replace(" ", "-")}-wrapper").length == 0
        addRelation(parasiteContainer, species, "parasite")
      if parasitesToAdd[species] == undefined
        parasitesToAdd[species] = []
      parentContainer = d3.select("##{species.replace(" ", "-").replace(".", "")}-ref-wrapper")
      addReference(parentContainer, references, parasitesToAdd[species])

updateEntry = () ->
  if $("#lifespan").val() != null
    lifespanInfo = {
      value: "#{$("#lifespan").val()}"
      references: lifespanReferences
    }
  else
    lifespanInfo = {}

  if $("#lifestyle").val() != null
    lifestyleInfo = {
      value: "#{$("#lifestyle").val()}"
      references: lifestyleReferences
    }
  else
    lifestyleInfo = {}

  if $("input#habit").val() != ""
    habitInfo = {
      value: "#{$("input#habit").val()}"
      references: habitReferences
    }
  else
    habitInfo = {}

  if $("input#chromosome").val() != ""
    chromosomeInfo = {
      value: "#{$("input#chromosome").val()}"
      references: chromosomeReferences
    }
  else
    chromosomeInfo = {}

  if $("input#genome").val() != ""
    genomeInfo = {
      value: "#{$("input#genome").val()}"
      references: genomeReferences
    }
  else
    genomeInfo = {}

  speciesInformation = {
    species: speciesId
    user: currentUser
    request_to: "update"
    submittedInformation: {
      lifespan: lifespanInfo
      lifestyle: lifestyleInfo
      habit: habitInfo
      chromosome_number: chromosomeInfo
      genome_size: genomeInfo
      hosts_to_add: hostsToAdd
      hosts_to_delete: hostsToDelete
      parasites_to_add: parasitesToAdd
      parasites_to_delete: parasitesToDelete
      species_name: $("#update-species-name").val()
    }
  }

  submittedInformation = "informationOverview=" + JSON.stringify(speciesInformation)

  Rails.ajax
    type: "POST"
    dataType: "json"
    contentType: 'application/json'
    url: "/submissions"
    data: submittedInformation

deleteEntry = () ->
  speciesInformation = {
    species: speciesId
    user: currentUser
    request_to: "destroy"
    submittedInformation: {}
  }

  submittedInformation = "informationOverview=" + JSON.stringify(speciesInformation)

  Rails.ajax
    type: "POST"
    dataType: "json"
    contentType: 'application/json'
    url: "/submissions"
    data: submittedInformation

resetForm = () ->
  $(".selectpicker").val('default')
  $(".selectpicker").selectpicker("refresh")
  setDefaultForm()

setDefaultForm = () ->
  # reset hosts/parasites listed
  d3.select("#hosts").selectAll("div").remove()
  d3.select("#parasites").selectAll("div").remove()
  setup()
  if hosts
    gon.unwatch('hosts', setDefaultForm)
  if parasites
    gon.unwatch('parasites', setDefaultForm)

setup = () ->
  hosts.forEach (element, index, array) ->
    addRelation(hostContainer, element, "host")

  parasites.forEach (element, index, array) ->
    addRelation(parasiteContainer, element, "parasite")

addReference = (parentContainer, references, thisDoiArray) ->
  if references[0].length == 0
    toastr.info('Adding as personal observation')
    references = ["personal observation"]

  references.forEach (reference, index, array) ->
    if !thisDoiArray.includes?(reference) && (thisDoiArray.length < 3)
      thisDoiArray.push(reference)

      container = parentContainer.append("div")
        .attr("class", "reference-wrapper")

      container.append("text")
        .html(reference)

      button = container.append("button", "svg")
        .attr("class", "btn")
        .attr("type", "submit")
        .attr("id", "delete-relation")
        .on("click", -> deleteRelation(container, undefined, "reference", thisDoiArray, reference))

      button.append("i")
        .attr("class", "fas fa-backspace")


distinguishLifeInfo = () ->
  if (this.id).includes("lifespan")
    addReference(d3.select("#lifespan-references"), $("#lifespan-reference-field").val().split(","), lifespanReferences)
  else if (this.id).includes("lifestyle")
    addReference(d3.select("#lifestyle-references"), $("#lifestyle-reference-field").val().split(","), lifestyleReferences)
  else if (this.id).includes("habit")
    addReference(d3.select("#habit-references"), $("#habit-reference-field").val().split(","), habitReferences)
  else if (this.id).includes("chromosome")
    addReference(d3.select("#chomosome-references"), $("#chromosome-reference-field").val().split(","), chromosomeReferences)
  else if (this.id).includes("genome")
    addReference(d3.select("#genome-references"), $("#genome-reference-field").val().split(","), genomeReferences)

# Add buttons
addButton = (parentContainer, elementId, text, functionToPerform) ->
  parentContainer.append("button", "svg")
    .attr("class", "btn custom-btn")
    .attr("id", elementId)
    .text(text)
    .on("click", functionToPerform)

###############
# Initial setup -- list all hosts and parasites
$('#lifespan').selectpicker({dropupAuto: false})
$("#lifestyle").selectpicker({dropupAuto: false})
$("#relation-type").selectpicker({dropupAuto: false})

$("#lifespan").prop("selectedIndex", -1)
$("#lifestyle").prop("selectedIndex", -1)
$("#relation-type").prop("selectedIndex", -1)

$("#lifespan").selectpicker("refresh")
$("#lifestyle").selectpicker("refresh")
$("#relation-type").selectpicker("refresh")

$("#lifespan-reference-field").val("")
$("#lifestyle-reference-field").val("")

$("input#habit").val("")
$("#habit-reference-field").val("")
$("input#chromosome").val("")
$("#chromosome-reference-field").val("")
$("input#genome").val("")
$("#genome-reference-field").val("")

$("#reference-field").val("")
$("#species").val("")
$("#image-authors").val("")
$("#image-location").val("")
$("#image-date").val("")

# add references
addButton(d3.select("#change-lifespan"), "add-lifespan-reference", "Add information", distinguishLifeInfo)
addButton(d3.select("#change-lifestyle"), "add-lifestyle-reference", "Add information", distinguishLifeInfo)
addButton(d3.select("#change-habit"), "add-habit-reference", "Add information", distinguishLifeInfo)
addButton(d3.select("#change-chromosome"), "add-chromosome-reference", "Add information", distinguishLifeInfo)
addButton(d3.select("#change-genome"), "add-genome-reference", "Add information", distinguishLifeInfo)
addButton(d3.select(".flex-container#add-relation"), "submit-relation", "Add information", checkAndProcessRelation)

# submit/reject
addButton(d3.select(".button-container"), "submit-form", "Submit", updateEntry)
addButton(d3.select(".button-container"), "reset-form", "Reset form", resetForm)
addButton(d3.select(".button-container"), "delete-form", "Delete this taxon", deleteEntry)

gon.watch('hosts', interval: 1000, setDefaultForm())
gon.watch('parasites', interval: 1000, setDefaultForm())



