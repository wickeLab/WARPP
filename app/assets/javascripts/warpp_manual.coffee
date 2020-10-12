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