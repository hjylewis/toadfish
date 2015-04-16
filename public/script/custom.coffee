# custom.coffee

DEBUG = true

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
  console.log "search: " + str
  return done null if str == ""
  return done JSON.parse(sessionStorage.getItem(str)) if sessionStorage.getItem(str)?
  async.parallel {
      "soundcloud": (callback) ->
        SC.get '/tracks', { q: str, limit: 10 }, (tracks, err) ->
          logError err if err?
          callback null, tracks
      ,"youtube": (callback) ->
        request = gapi.client.youtube.search.list {
          q: str,
          type: 'video',
          maxResults: 10,
          part: 'snippet'
        }
        request.execute (response) ->
          callback null, response.items
      ,"rdio": (callback) ->
        $.ajax {
          url: '/rdio/search',
          data: {'q': str},
          success: (res) ->
              callback null, res
        }
    }, (err, results) ->
      results.query = str
      sessionStorage.setItem(str, JSON.stringify(results))
      done results

logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    not DEBUG