DEBUG = true
rdioLoaded = false
googleLoaded = false


SC.initialize {
    client_id: "3baff77b75f4de090413f7aa542254cd"
}

googleApiClientReady = ->
  gapi.client.setApiKey 'AIzaSyDxetqce82LNsSBK4aSQ_7sSFDelsRtwSM'
  gapi.client.load 'youtube', 'v3'
  googleLoaded = true
  if (host == true)
	  loadPlaylist()

if (host == true)
	#youtube stuff
	tag = document.createElement('script')
	tag.src = "https://www.youtube.com/iframe_api"
	firstScriptTag = document.getElementsByTagName('script')[0]
	firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

	#rdio stuff
	rdio_player = null;
	$.ajax {
		url: '/rdio/playbackToken',
		success: (res) ->
			flashvars = {
				'playbackToken': res,
				'domain': 'localhost',            
				'listener': 'callback_object'    # the global name of the object that will receive callbacks from the SWF
			}
			params = {
				'allowScriptAccess': 'always'
			}
			swfobject.embedSWF('http://www.rdio.com/api/swf/', 'rdio_player', 1, 1, '9.0.0', 'expressInstall.swf', flashvars, params, {})
	}


callback_object = {}
# Called once the API SWF has loaded and is ready to accept method calls.
callback_object.ready = (user) ->
	rdio_player = $('#rdio_player').get(0)
	rdio_player.rdio_startFrequencyAnalyzer({
		frequencies: '10-band',
		period: 100
	})
	rdioLoaded = true
	loadPlaylist()
	console.log(user)
callback_object.positionChanged = (position) ->
	playlist.positionChanged "rdio", position

callback_object.playStateChanged = (playState) ->
	if (playState == 2)
		playlist.state = 0
	else if (playState == 1)
		playlist.state = 1
	else if (playState == 0 || playState == 4)
		playlist.state = 2
	else if (playState == 3)
		playlist.state = 3

logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    not DEBUG