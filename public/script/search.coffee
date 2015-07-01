# search.coffee

PAGE_LENGTH = 3
waiting_time = -1

keystroke_count_down = ->
  if waiting_time == 0
    waiting_time = -1
    value = $("#first_search").val()
    search value, (res) ->
      console.log res
      display_result(res)
  else
    waiting_time -= 1

setInterval keystroke_count_down, 100

display_result = (results) ->
  $("#result_list").removeClass "hidden-ul"
  $("#result_list").children().hide()
  _.each results, (res, name) ->
    if (res != null && res.collections && res.collections.length > 0) 
      $("#result_list").append("<li class = 'seperator'>#{name}</li>")
      _.each res.collections, (item) ->
        $("#result_list").append $("<li class = 'result' data-song='#{JSON.stringify item}'><h2><a href='#{item.permalink_url}' target='_blank'>#{item.title}</a></h2><span>#{item.artist || ""}</span>
        <img src='#{item.artwork_url}' /><br /></li>").append($("<a class='add_button add_to_playlist'>Add to Playlist</a>").click ->
          playlist.add $(this).parent().data().song
        ).append $("<a class='add_button play_now'>Play Now</a>").click ->
          playlist.addFirst $(this).parent().data().song

$('#first_search').keyup (e) ->
  waiting_time = 3
  if e.key == 13
    waiting_time = 0
    keystroke_count_down()

# str: string query
# options: object (optional)
#    next: boolean, get another page.  DEFAULT: false
#    types: array, of 'soundcloud','youtube','rdio'.  DEFAULT: ['soundcloud','youtube','rdio']
# done: callback function(obj)
search = (str, options, done) ->
  if _.isFunction(options)
    done = options
    options = {}
  options.types = ['soundcloud','youtube','rdio'] if not options.types?
  console.log "search: " + str
  return done null if str == ""
  
  storedResults = if sessionStorage.getItem(str) then JSON.parse(sessionStorage.getItem(str)) else {}
  if not options.next?
    ret = _.reduce options.types, ((memo, type) -> return storedResults[type] && memo), true
    return (done storedResults) if ret?
    options.types = _.filter options.types, (type) -> return not storedResults[type]

  async.parallel {
      "soundcloud": (callback) ->

        return callback null, null if _.indexOf(options.types,'soundcloud') == -1
        if options.next && storedResults.soundcloud && storedResults.soundcloud.next
          $.ajax(storedResults.soundcloud.next)
            .done (tracks) ->
              callback null, cleanUpResults(tracks, "soundcloud")
            .fail (jqXHR, textStatus, errorThrown) ->
              logError "soundcloud err:" + textStatus + ": " + errorThrown
        else
          SC.get '/tracks', { q: str, limit: PAGE_LENGTH, linked_partitioning: 1}, (tracks, err) ->
            logError "soundcloud err:" + err if err?
            callback null, cleanUpResults(tracks, "soundcloud")
      ,"youtube": (callback) ->
        return callback null, null if _.indexOf(options.types,'youtube') == -1
        ytOptions = {
          q: str,
          type: 'video',
          maxResults: PAGE_LENGTH,
          part: 'snippet'
        }
        ytOptions.pageToken = storedResults.youtube.next if options.next && storedResults.youtube && storedResults.youtube.next?
        request = gapi.client.youtube.search.list ytOptions
        request.execute (response) ->
          logError "youtube err:" + JSON.stringify(response.error) if response.error?
          callback null, cleanUpResults(response, "youtube")
      ,"rdio": (callback) ->
        return callback null, null if _.indexOf(options.types,'rdio') == -1
        page = if options.next && storedResults.rdio && storedResults.rdio.next then storedResults.rdio.next else 0
        $.ajax {
          url: '/rdio/search',
          data: {'q': str, 'page_length': PAGE_LENGTH, 'page': page},
          success: (res) ->
              callback null, cleanUpResults(res, "rdio")
        }
    }, (err, results) ->
      results = _.mapObject results, (obj, type) ->
        obj = {} if not obj
        collections = if storedResults[type] then storedResults[type].collections.concat(obj.collections || []) else obj.collections
        next = obj.next || (storedResults[type].next if storedResults[type])
        if collections && next
          return {
            collections: collections,
            next: next
          }
        else
          return null
      results.query = str
      sessionStorage.setItem(str, JSON.stringify(results)) #if not DEBUG
      done results

cleanUpResults = (results, type) ->
  resultObj = {}
  resultObj.next = results.next_href || results.nextPageToken || results.next_page

  results = results.collection || results.items

  resultObj.collections = _.map results, (result) ->
    retObj = {}
    retObj.id = result.key || result.id.videoId || result.id
    retObj.permalink_url = result.permalink_url || result.shortUrl || ('https://www.youtube.com/watch?v=' + retObj.id if type == 'youtube')
    retObj.title = result.title || result.name || result.snippet.title
    retObj.artist = result.artist if result.artist?
    retObj.duration = result.duration if result.duration?
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
    if (!retObj.artwork_url)
      retObj.artwork_url = "/images/no_image.jpg"
    return retObj

  return resultObj

