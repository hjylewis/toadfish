# search.coffee

PAGE_LENGTH = 10

class Search
  search: (str, options, done) ->
    if (!str)
      return done {
        query: str,
        results: []
      }

    if (!options)
      options = {}

    if _.isFunction(options)
      done = options
      options = {}
    options.types = ['soundcloud','youtube','rdio'] if not options.types?
    retTypes = options.types
    return done null if str == ""

    storedResults = if sessionStorage.getItem(str) then JSON.parse(sessionStorage.getItem(str)) else { results: {} }
    if not options.next?
      ret = _.reduce options.types, ((memo, type) -> return storedResults.results[type] && memo), true
      return (done storedResults) if ret?
      options.types = _.filter options.types, (type) -> return not storedResults.results[type]

    async.parallel {
        "soundcloud": (callback) =>

          return callback null, null if _.indexOf(options.types,'soundcloud') == -1
          if options.next && storedResults.results.soundcloud && storedResults.results.soundcloud.next
            $.ajax(storedResults.results.soundcloud.next)
              .done (tracks) =>
                callback null, @cleanUpResults(tracks, "soundcloud")
              .fail (jqXHR, textStatus, errorThrown) ->
                logError "soundcloud err:" + textStatus + ": " + errorThrown
          else
            SC.get '/tracks', { q: str, limit: PAGE_LENGTH, linked_partitioning: 1}, (tracks, err) =>
              logError "soundcloud err:" + err if err?
              callback null, @cleanUpResults(tracks, "soundcloud")
        ,"youtube": (callback) =>
          return callback null, null if _.indexOf(options.types,'youtube') == -1
          ytOptions = {
            q: str,
            type: 'video',
            maxResults: PAGE_LENGTH,
            part: 'snippet'
          }
          ytOptions.pageToken = storedResults.results.youtube.next if options.next && storedResults.results.youtube && storedResults.results.youtube.next?
          request = gapi.client.youtube.search.list ytOptions
          request.execute (response) =>
            logError "youtube err:" + JSON.stringify(response.error) if response.error?
            callback null, @cleanUpResults(response, "youtube")
        ,"rdio": (callback) =>
          return callback null, null if _.indexOf(options.types,'rdio') == -1
          page = if options.next && storedResults.results.rdio && storedResults.results.rdio.next then storedResults.results.rdio.next else 0
          $.ajax {
            url: '/rdio/search',
            data: {'q': str, 'page_length': PAGE_LENGTH, 'page': page},
            success: (res) =>
                callback null, @cleanUpResults(res, "rdio")
          }
      }, (err, results) ->
        ret = {}
        storeResults = _.mapObject results, (obj, type) ->
          obj = {} if not obj
          collections = if storedResults.results[type] then storedResults.results[type].collections.concat(obj.collections || []) else obj.collections
          next = obj.next || (storedResults.results[type].next if storedResults.results[type])
          if collections && next
            return {
              collections: collections,
              next: next
            }
          else
            return null

        results = _.mapObject storeResults, (obj, type) ->
          return if retTypes.indexOf(type) != -1 then obj else null

        ret.query = str
        ret.results = storeResults
        sessionStorage.setItem(str, JSON.stringify(ret)) #if not DEBUG
        ret.results = results
        done ret

  cleanUpResults: (results, type) ->
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
          retObj.artwork_small = result.artwork_url
          retObj.artwork_url = result.artwork_url.replace('large','t500x500')
        else if result.user.avatar_url? && result.user.avatar_url.indexOf('a1') == -1
          retObj.artwork_small = result.user.avatar_url
          retObj.artwork_url = result.user.avatar_url.replace('large','t500x500')
      else if type == 'rdio' 
        retObj.artwork_small = result.icon if result.icon?
        retObj.artwork_url = result.icon400.replace('400','600') if result.icon400?
      else if type == 'youtube'
        retObj.artwork_small = result.snippet.thumbnails.default.url
        retObj.artwork_url = result.snippet.thumbnails.high.url
      if (!retObj.artwork_url)
        retObj.artwork_url = "/images/no_image.jpg"
      return retObj

    return resultObj


search = new Search
