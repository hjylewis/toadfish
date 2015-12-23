#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500

socket = io(window.location.origin)
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)
	if host
		$.post('/host/'+roomID+'/login', {
			roomID: roomID,
			socketID: socket.id
		})

# TODO: state
# 0: stop
# 1: play
# 2: pause
# 3: buffer

class Playlist
	constructor: () ->
		@currentIndex = 0
		@playlist = []
		@state = 0
		@volume = 100
		@autoplay = false
		$.get '/sessionID', (sessionID) =>
			@sessionID = sessionID
		socket.on 'update', (update) =>
			if update.socketID != socket.id
				@readUpdate(update)
		socket.on 'no host', () =>
			window.location.reload()

	load: (playlistSettings) ->
		@currentIndex = playlistSettings.currentIndex || 0
		@playlist = if playlistSettings.playlist then JSON.parse(playlistSettings.playlist) else []
		@volume = playlistSettings.volume || 100

		if host
			@save "autoplay", "false"
		else
			@autoplay = if playlistSettings.autoplay then JSON.parse(playlistSettings.autoplay) else false
			@state = playlistSettings.state || 0

		scope = angular.element($("body")).scope()
		if (!scope.$$phase && !scope.$root.$$phase)
			scope.$apply()

		if @playlist.length > 0
			@loadSong () =>
				@setVolume @volume
				@play() #auto play

	getCurrentSong: () ->
		if @autoplay
			return { song_details: @autoplay }
		else
			return @playlist[@currentIndex]

	play: (update) ->
		return if !host
		if (@playlist.length == 0)
			console.log "nothing here"
		else if @state == 1
			console.log "Already playing"
		else
			song = @getCurrentSong()
			if (song.song_details.type == "soundcloud")
				SC.sound.play()
			else if (song.song_details.type == "youtube")
				yt_player.playVideo()
				@state = 1
				@positionChanged "youtube"
			else if (song.song_details.type == "rdio")
				rdio_player.rdio_play()
			@save('play') if !update
		@state = 1
			# set state


	pause: (update) ->
		return if !host
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			SC.sound.pause()
		else if (song.song_details.type == "youtube")
			yt_player.pauseVideo()
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_pause()
		@state = 2
		@save('pause') if !update
			
		# set state		

	stop: (update) ->
		return if !host
		song = @getCurrentSong()
		try
			if (song.song_details.type == "soundcloud")
				SC.sound.stop()
			else if (song.song_details.type == "youtube")
				yt_player.stopVideo()
			else if (song.song_details.type == "rdio")
				rdio_player.rdio_stop()
		@state = 0
		@save('stop') if !update

	seek: (percent) ->
		return if !host
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			SC.sound.setPosition(song.song_details.duration * (percent / 100))
		else if (song.song_details.type == "youtube")
			yt_player.seekTo(yt_player.getDuration() * (percent / 100))
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_seek(song.song_details.duration * (percent / 100))

	setVolume: () ->
		return if !host
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			SC.sound.setVolume(@volume)
		else if (song.song_details.type == "youtube")
			yt_player.setVolume(@volume)
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_setVolume(@volume / 100)

	# add_autoplay: just added the autoplay song, so don't stop or reload the song
	next: (update, add_autoplay) ->
		if (@currentIndex + 1 < @playlist.length )
			@stop(true) if !add_autoplay
			@autoplay = false
			@currentIndex++
			@save('next', @currentIndex.toString()) if !update
			if !add_autoplay
				@loadSong () => #might wanna make is so it doesn't play if player is paused
					@setVolume @volume
					@play()
		else 
			@startAutoPlay()

	prev: (update) ->
		if (@currentIndex > 0)
			@stop(true)
			@currentIndex--
			@save('prev', @currentIndex.toString()) if !update
			@loadSong () =>
				@setVolume @volume
				@play()
		else 
			@seek(0)

	goTo: (index, update) ->
		if (index >= 0 && index < @playlist.length)
			@stop(true)
			@autoplay = false
			@currentIndex = index
			@save('goTo', @currentIndex.toString()) if !update
			@loadSong () =>
				@setVolume @volume
				@play()
		return false

	add: (song_details, update) ->
		song_details.uuid = generateUUID()
		song_obj = if song_details.song_details then song_details else {
			song_details: song_details,
			user: @sessionID,
			time: Date.now()
		}
		@playlist.push(song_obj)
		@save('add', JSON.stringify(song_obj)) if !update
		if (@playlist.length == 1)
			@loadSong () =>
				@setVolume @volume
				@play() #auto play
		if (@currentIndex + 2 == @playlist.length && (@state == 0 || @autoplay))
			@next(update || !host, @autoplay && (@autoplay.id == song_details.id))

	addFirst: (song_details, update) ->
		if (@playlist.length == 0)
			@add(song_details, update)
		else
			song_details.uuid = generateUUID()
			song_obj = if song_details.user then song_details else {
				song_details: song_details,
				user: @sessionID,
				time: Date.now()
			}
			@playlist.splice(@currentIndex + 1, 0, song_obj)
			@next(update || !host)
			@save "addFirst", JSON.stringify(song_obj) if !update

	remove: (index, update) ->
		if (index < @currentIndex)
			@playlist.splice(index, 1)
			@currentIndex--
		else if (index == @currentIndex)
			@stop(true) if not @autoplay
			@playlist.splice(index, 1)
			if (@currentIndex == @playlist.length && @playlist.length != 0)
				@currentIndex--
			if not @autoplay
				@loadSong () =>
					@setVolume @volume
					@play() #auto play
		else
			@playlist.splice(index, 1)

		@save('remove', index.toString()) if !update

	move: (from, to, update) ->
		song = @playlist.splice(from, 1)[0]
		@playlist.splice(to, 0, song)
		if (from < @currentIndex && to >= @currentIndex)
			@currentIndex--
		else if (from > @currentIndex && to <= @currentIndex)
			@currentIndex++
		else if (from == @currentIndex)
			@currentIndex = to
		@save('move', JSON.stringify({from: from, to: to})) if !update

	setPlayState: (state) =>
		scope = angular.element($("body")).scope()
		if (scope.$$phase || scope.$root.$$phase)
			scope.playlist.state = state
		else
			scope.$apply(scope.playlist.state = state)

	startAutoPlay: () ->
		return if !host
		song = @getCurrentSong()
		@stop()
		@autoplay = true

		# In case of error
		seekEnd = () =>
			@autoplay = false
			@state = 0
			@seek(100) # seek end of song
			@stop()

		switch (song.song_details.type)
			when "rdio"
				rdio_player.rdio_play(song.song_details.radioKey)
				@setVolume @volume
				@play()
				return
			when "soundcloud"
				SC.get '/tracks/' + song.song_details.id + '/related', {limit: 5}, (tracks, err) =>
					if (err)
						seekEnd()
					else
						track = tracks[Math.floor(Math.random() * 5)]
						song_details = search.cleanUpResults({collection: [track]}, 'soundcloud').collections[0]
						@autoplay = song_details
						@loadSong () =>
							@setVolume @volume
							@play() #auto play
						@save 'autoplay', JSON.stringify(song_details)
			when "youtube"
				ytOptions = {
					relatedToVideoId: song.song_details.id,
					videoEmbeddable: true,
					type: 'video',
					maxResults: 5,
					part: 'snippet'
				}
				request = gapi.client.youtube.search.list ytOptions
				request.execute (response) =>
					if (response.error)
						seekEnd()
					else
						track = response.items[Math.floor(Math.random() * 5)]
						song_details = search.cleanUpResults({items: [track]}, 'youtube').collections[0]
						@autoplay = song_details
						@loadSong () =>
							@setVolume @volume
							@play() #auto play
						@save 'autoplay', JSON.stringify(song_details)

	loadArt: () ->
		song = @getCurrentSong()
		if !song
			$("body").css "background-image", ""
			return
		song_details = song.song_details

		$("body").css "background-image", "linear-gradient(rgba(0, 0, 0, 0.2),rgba(0, 0, 0, 0.2)),url('#{song_details.artwork_url || ""}')"
		$("body").css "background-size", "cover"
		$("body").css "background-attachment", "fixed"

	loadSong: (cb) -> 
		if (cb == undefined)
			cb = () ->

		song = @getCurrentSong()
		if (!song && @currentIndex > 0)
			@currentIndex--
			song = @getCurrentSong()

		@loadArt()

		return if !song

		song_details = song.song_details
		
		
		if host
			_this = @
			if (song_details.type == "soundcloud")
				SC.stream "/tracks/" + song_details.id, {
						whileplaying: () ->
							_this.positionChanged "soundcloud", this.position
						onload: () ->
							if (this.readyState == 2)
								console.log "sc error"
								song.song_details.error = true
								_this.save("error", _this.currentIndex.toString())
								song.obj = null
								_this.next()
						onplay: () ->
							_this.setPlayState 1
						onstop: () ->
							_this.setPlayState 0
						onpause: () ->
							_this.setPlayState 2
						onbufferchange: () ->
							if (this.isBuffering) 
								_this.setPlayState 3
							else
								_this.setPlayState 1
					}, (sound) ->
						SC.sound = sound
						cb()
			else if (song_details.type == "youtube")
				if (yt_player == null)
					yt_player = new YT.Player('yt_player', {
						height: '0',
						width: '0',
						videoId: song_details.id,
						playerVars: {'autoplay': 0, 'controls': 0, rel: 0},
						events: {
							'onReady': () ->
								yt_player.unMute()
								cb()
							'onStateChange': (event) =>
								if (event.data == YT.PlayerState.PLAYING)
									@setPlayState 1
								else if (event.data == YT.PlayerState.PAUSED)
									@setPlayState 2
								else if (event.data == YT.PlayerState.BUFFERING)
									@setPlayState 3
								else if (event.data == -1)
									@setPlayState 0
						}
			        })
				else
					yt_player.loadVideoById(song_details.id)
					cb()
			else if (song_details.type == "rdio")
				rdio_player.rdio_play(song_details.id)
				rdio_player.rdio_pause()
				cb()

	positionChanged: (type, position) ->
		return if !host
		if (type == @getCurrentSong().song_details.type && @state != 0)
			# update graphics
			percent = null;
			if (type == "youtube")
				if (position == undefined)
					return @positionChanged "youtube", (yt_player.getCurrentTime() || 0)
				setTimeout((() =>
					if (yt_player.getPlayerState() == 1 || yt_player.getPlayerState() == 3)
						@positionChanged "youtube", yt_player.getCurrentTime()
					), YT_TIME_INTERVAL)
				percent = (position / yt_player.getDuration()) * 100
			else 
				percent = (position / @getCurrentSong().song_details.duration) * 100
			$('#seekbar').attr("value",  percent)
			if (type == "rdio" && !rdio_user && position > 29)
				scope = angular.element($("body")).scope()
				openModal = () ->
					if (scope.firstModal)
						scope.modals.push('rdio')
						scope.firstModal = false
				if (scope.$$phase || scope.$root.$$phase) then openModal() else scope.$apply(openModal())
				@next()
			else if percent > 99.5
				@next()
	sendUpdate: (type, data) ->
		$.post('/sendUpdate', {
			type: type,
			roomID: roomID,
			host: host,
			data: data,
			socketID: socket.id
		}).fail (data) =>
			if (data.responseText == "User has been banned")
				@reload()
				scope = angular.element($("body")).scope()
				if (scope.$$phase || scope.$root.$$phase) then (scope.modals.push('banned')) else scope.$apply(scope.modals.push('banned'))

	readUpdate: (update) ->
		if (ENV == 'dev')
			console.log update

		switch (update.type)
			when "addFirst"
				@addFirst JSON.parse(update.data), true
			when "add"
				@add JSON.parse(update.data), true
			when "next"
				@next true
			when "prev"
				@prev true
			when "goTo"
				@goTo parseInt(update.data), true
			when "remove"
				@remove parseInt(update.data), true
			when "play"
				@state = 1
			when "pause"
				@state = 2
			when "stop"
				@state = 0
			when "move"
				data = JSON.parse(update.data)
				@move parseInt(data.from), parseInt(data.to), true
			when "error"
				@playlist[parseInt(update.data)].song_details.error = true
			when "autoplay"
				@autoplay = JSON.parse(update.data)
				@loadArt()
		scope = angular.element($("body")).scope()
		if (!scope.$$phase && !scope.$root.$$phase)
			scope.$apply()
		@saveToDB(update.type) if host
	save: (type, data) ->
		@sendUpdate type, data
		@saveToDB(type) if host
		# @reload() if !host && type == "add"
	saveToDB: (type) ->
		playlistArray = ["add", "addFirst", "move", "remove", "error", "playlist"]
		indexArray = ["next", "prev", "goTo", "move", "remove", "index"]
		autoplayArray = ["autoplay", "next", "goTo"]

		switch (type)
			when "play"
				state = "1"
			when "pause"
				state = "2"
			when "stop"
				state = "0"
			when "state"
				state = JSON.stringify(@state)

		if (playlistArray.indexOf(type) != -1)
			stripped_playlist = _.map @playlist, (song) ->
				return _.omit(song, 'obj')

		if (indexArray.indexOf(type) != -1)
			currentIndex = JSON.stringify(@currentIndex)

		if (autoplayArray.indexOf(type) != -1)
			autoplay = @autoplay

		playlistSettings = {
			currentIndex: currentIndex,
			playlist: stripped_playlist,
			volume: JSON.stringify(@volume),
			state: state,
			autoplay: JSON.stringify(autoplay),
		}
		$.post('/savePlaylist', { 
			playlistSettings: JSON.stringify(playlistSettings),
			roomID: roomID
		})
	reload: () ->
		$.get '/' + roomID + '/playlistSettings', (settings) =>
			@load settings

# TODO move to utilities eventually
generateUUID  = () ->
    d = new Date().getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
        r = (d + Math.random()*16)%16 | 0
        d = Math.floor(d/16)
        return (if c=='x' then r else (r&0x3|0x8)).toString(16)
    return uuid




