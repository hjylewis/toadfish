# search.coffee

PAGE_LENGTH = 10

class Search
  constructor: () ->
    @storage = {}
    @storageSupport = true
    try
      sessionStorage.setItem('test', '1')
      sessionStorage.removeItem('test')
      @storageSupport = true
    catch error
      @storageSupport = false

  getEnabled: (cb) ->
    $.get '/' + roomID + '/enabled', (obj) ->
      types = _.keys(_.pick(obj, (val, key, obj) -> return val))
      cb types

  search: (str, options, done) ->
    _this = @
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
    return done null if str == ""

    if options.types
      @_search(str, options, done)
    else
      @getEnabled (types) =>
        options.types = types
        @_search(str, options, done)

  _search: (str, options, done) ->
    retTypes = options.types

    if @storageSupport && sessionStorage.getItem(str)
      storedResults = JSON.parse(sessionStorage.getItem(str))
    else if @storage[str]
      storedResults = JSON.parse(@storage[str])
    else
      storedResults = { results: {} }

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
            videoEmbeddable: true,
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
        ,"local": (callback) =>
          return callback null, null if _.indexOf(options.types,'local') == -1
          page = if options.next && storedResults.results.local && storedResults.results.local.next then storedResults.results.local.next else 0
          $.ajax {
            url: '/localsong/' + roomID + '/search',
            data: {'q': str, 'page_length': PAGE_LENGTH, 'page': page},
            success: (res) =>
                callback null, @cleanUpResults(res, "local")
          }

      }, (err, results) =>
        if (ENV == 'dev')
          console.log results
        ret = {}
        storeResults = _.mapObject results, (obj, type) ->
          obj = {} if not obj
          collections = if storedResults.results[type] then storedResults.results[type].collections.concat(obj.collections || []) else obj.collections
          next = obj.next || (storedResults.results[type].next if storedResults.results[type])
          if collections && collections.length > 0 && next
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
        if _this.storageSupport
          sessionStorage.setItem(str, JSON.stringify(ret))
        else #safari
          _this.storage[str] = JSON.stringify(ret)
        ret.results = results
        done ret

  cleanUpResults: (results, type) ->
    resultObj = {}
    resultObj.next = results.next_href || results.nextPageToken || results.next_page

    results = results.collection || results.items

    resultObj.collections = _.map results, (result) ->
      retObj = {}
      retObj.id = result.key || result._id || result.id.videoId || result.id
      retObj.permalink_url = result.permalink_url || result.url || result.shortUrl || ('https://www.youtube.com/watch?v=' + retObj.id if type == 'youtube')
      retObj.title = result.title || result.name || result.snippet.title
      retObj.artist = result.artist if result.artist?
      retObj.duration = result.duration if result.duration?
      retObj.user = result.user.username if result.user?
      retObj.type = type
      retObj.radioKey = result.radioKey

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
      else if type == 'local'
        retObj.artwork_url = retObj.artwork_small = result.artwork_url
      if (!retObj.artwork_url)
        retObj.artwork_url = "/images/no_image.jpg"
      else
        retObj.artwork_url = retObj.artwork_url.replace('http:','https:')
        retObj.artwork_small = retObj.artwork_small.replace('http:','https:')
      return retObj

    return resultObj


search = new Search
