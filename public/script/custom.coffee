# custom.coffee

SC.initialize {
    client_id: "3baff77b75f4de090413f7aa542254cd"
}

googleApiClientReady = ->
  gapi.client.setApiKey 'AIzaSyDxetqce82LNsSBK4aSQ_7sSFDelsRtwSM'
  gapi.client.load 'youtube', 'v3'


$('#first_search').keyup (e) ->
  value = $(this).val()
  search value, (res) ->
    console.log res
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

search = (str, done) ->
  console.log str
  return null if str == ""
  return JSON.parse(sessionStorage.getItem(str)) if sessionStorage.getItem(str)?
  console.log "nope"
  async.parallel {
      "soundcloud": (callback) ->
        SC.get '/tracks', { q: str }, (tracks, err) ->
          callback null, tracks
      ,"youtube": (callback) ->
        request = gapi.client.youtube.search.list {
          q: str,
          part: 'snippet'
        }
        request.execute (response) ->
          callback null, response.items
    }, (err, results) ->
      results.query = str
      done results
