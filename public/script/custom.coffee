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
          logError "soundcloud err:" + err if err?
          callback null, cleanUpResults(tracks, "soundcloud")
      ,"youtube": (callback) ->
        request = gapi.client.youtube.search.list {
          q: str,
          type: 'video',
          maxResults: 10,
          part: 'snippet'
        }
        request.execute (response) ->
          logError "youtube err:" + JSON.stringify(response.error) if response.error?
          callback null, cleanUpResults(response.items, "youtube")
      ,"rdio": (callback) ->
        $.ajax {
          url: '/rdio/search',
          data: {'q': str},
          success: (res) ->
              callback null, cleanUpResults(res, "rdio")
        }
    }, (err, results) ->
      results.query = str
      sessionStorage.setItem(str, JSON.stringify(results))
      done results

cleanUpResults = (results, type) ->
  _.map results, (result) ->
    retObj = {}
    retObj.id = result.key || result.id.videoId || result.id
    retObj.permalink_url = result.permalink_url || result.shortUrl || ('https://www.youtube.com/watch?v=' + retObj.id if type == 'youtube')
    retObj.title = result.title || result.name || result.snippet.title
    retObj.artist = result.artist
    retObj.duration = result.duration
    retObj.user = result.user.username if result.user?
    retObj.type = type

    if type == 'soundcloud'
      if result.artwork_url?
        retObj.artwork_url = result.artwork_url.replace('large','t500x500')
      else if result.user.avatar_url? && not result.user.avatar_url.includes('a1')
        retObj.artwork_url = result.user.avatar_url.replace('large','t500x500')
    else if type == 'rdio'
      retObj.artwork_url = result.icon400.replace('400','600') if result.icon400?
    else if type == 'youtube'
      retObj.artwork_url = result.snippet.thumbnails.high.url
    return retObj


logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    not DEBUG