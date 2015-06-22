DEBUG = true


SC.initialize {
    client_id: "3baff77b75f4de090413f7aa542254cd"
}

googleApiClientReady = ->
  gapi.client.setApiKey 'AIzaSyDxetqce82LNsSBK4aSQ_7sSFDelsRtwSM'
  gapi.client.load 'youtube', 'v3'


#youtube stuff
tag = document.createElement('script')
tag.src = "https://www.youtube.com/iframe_api"
firstScriptTag = document.getElementsByTagName('script')[0]
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)

#rdio stuff
apiswf = null;
flashvars = {
	'playbackToken': "FglVhvtZ_____1RDTXEzbzQtME5xVHZkWGtvWFJwYndsb2NhbGhvc3T0N1Hvz9ghkI_YzHoIZHzx", # from http://rdioconsole.appspot.com/#domain%3Dlocalhost%26method%3DgetPlaybackToken.js
	'domain': 'localhost',            
	'listener': 'callback_object'    # the global name of the object that will receive callbacks from the SWF
}
params = {
	'allowScriptAccess': 'always'
}
attributes = {}
swfobject.embedSWF('http://www.rdio.com/api/swf/', # the location of the Rdio Playback API SWF
	'apiswf', # the ID of the element that will be replaced with the SWF
	1, 1, '9.0.0', 'expressInstall.swf', flashvars, params, attributes)

callback_object = {};

callback_object.ready = (user) ->
          # Called once the API SWF has loaded and is ready to accept method calls.

          # find the embed/object element
	apiswf = $('#apiswf').get(0)

	apiswf.rdio_startFrequencyAnalyzer({
		frequencies: '10-band',
		period: 100
	})
	console.log(user)

logError = (msg) ->
  $.post "/error", { "msg" : msg }

window.onerror = (msg, url, line) ->
    message = "clientError: "+url+"["+line+"] : "+msg
    logError message
    not DEBUG