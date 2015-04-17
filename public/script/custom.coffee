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

logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    not DEBUG

cleanUpResults = (results, type) ->
  _.map results, (result) ->
    if type == 'soundcloud'
      scObj =  _.pick(result, 'artwork_url','duration','id','permalink_url','title')
      scObj.user = result.user.username
      if scObj.artwork_url?
        scObj.artwork_url = scObj.artwork_url.replace('large','t500x500')
      else
        scObj.artwork_url = result.user.avatar_url.replace('large','t500x500') if  result.user.avatar_url?
      return _.extend scObj, {type: 'soundcloud'}
    if type == 'youtube'
      ytObj = {}
      ytObj.id = result.id.videoId
      ytObj.artwork_url = result.snippet.thumbnails.high.url
      ytObj.permalink_url = 'https://www.youtube.com/watch?v=' + ytObj.id
      ytObj.title = result.snippet.title
      return _.extend ytObj, {type: 'youtube'}
    if type == 'rdio'
      rdioObj = {}
      rdioObj.id = result.key
      rdioObj.artwork_url = result.icon400.replace('400','600') if result.icon400?
      rdioObj.permalink_url = result.shortUrl
      rdioObj.title = result.name
      rdioObj.artist = result.artist
      rdioObj.duration = result.duration
      return _.extend rdioObj, {type: 'rdio'}