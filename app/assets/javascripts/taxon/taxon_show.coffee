imageAttributions = JSON.parse(gon.image_attributions)

fieldText = {
  creator: "Rights holder",
  publisher: "Publisher",
  reference: "Source",
  license_url: "Distributed under",
  license: "License",
  created: "Observed on",
  location: "Location (estimation)"
}

convertText = (field, text) ->
  if field == "license_url" || field == "reference"
    return "<a href=#{text} target='_blank'>#{text}</a>"
  else
    return text


$('.image-slider')
  .slick({
    dots: true,
    infinite: true,
    autoplay: true,
    autoplaySpeed: 2000,
    centerMode: true,
    variableWidth: true,
    pauseOnHover: true,
    prevArrow: '<button type="button" class="fas fa-chevron-left"></button>'
    nextArrow: '<button type="button" class="fas fa-chevron-right"></button>'
  })
  .on('beforeChange', (event, slick, currentSlide, nextSlide) ->
      Object.keys(imageAttributions[nextSlide]).forEach (field) ->
        text = convertText(field, imageAttributions[nextSlide][field])
        d3.select("#td-#{field}").html(text)
  )

table = d3.select(".attribution").append("table")
Object.keys(imageAttributions[0]).forEach (field) ->
  row = table.append("tr")
  row.append("td")
    .html(fieldText[field])
  text = convertText(field, imageAttributions[0][field])
  row.append("td")
    .attr("id", "td-#{field}")
    .html(text)