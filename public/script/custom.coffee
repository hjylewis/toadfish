# custom.coffee


$('#first_search').keyup (e) ->
  value = $(this).val()
  first = true
  any = false
  $("ul li.result").each (item) ->
    text = "*" + $(this).text() + "*"
    if text.match(value) and value
      any = true
      if first
        $(this).addClass 'no_border_result'
        first = false
      else
        $(this).removeClass 'no_border_result'
      $(this).removeClass('hidden_result')
    else
      $(this).addClass("hidden_result")
      $(this).removeClass 'no_border_result'

    if not any
      $('ul').addClass('hidden-ul')
    else
      $('ul').removeClass('hidden-ul')
