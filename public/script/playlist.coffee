#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500
yt_obj = {artwork_url: "https://i.ytimg.com/vi/ih2xubMaZWI/hqdefault.jpg", id: "ih2xubMaZWI", permalink_url: "https://www.youtube.com/watch?v=ih2xubMaZWI", title: "OMFG - Hello",type: "youtube"}
sc_obj = {artwork_url: "https://i1.sndcdn.com/artworks-000110807035-1bxk4l-t500x500.jpg", duration: 226371, id: 178220277, permalink_url: "https://soundcloud.com/alexomfg/omfg-hello", title: "OMFG - Hello", type: "soundcloud", user: "OMFG"}
rd_obj = {artist: "OMFG", artwork_url: "http://img02.cdn2-rdio.com/album/8/3/5/000000000050f538/2/square-600.jpg", duration: 226, id: "t60862619", permalink_url: "http://rd.io/x/QitB__PE/", title: "Hello", type: "rdio"}

socket = io(window.location.origin)
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)

generateUUID  = () ->
    d = new Date().getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
        r = (d + Math.random()*16)%16 | 0
        d = Math.floor(d/16)
        return (if c=='x' then r else (r&0x3|0x8)).toString(16)
    return uuid

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
		@lastRdioStation = null
		socket.on 'update', (update) =>
			@readUpdate(update)

	load: (playlistSettings) ->
		@currentIndex = playlistSettings.currentIndex || 0
		@state = 0
		@playlist = if playlistSettings.playlist then JSON.parse(playlistSettings.playlist) else []
		@volume = playlistSettings.volume || 100
		@lastRdioStation = playlistSettings.lastRdioStation || null
		@save "autoplay", false
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
		if (@playlist.length == 0)
			console.log "nothing here"
		else if @state == 1
			console.log "Already playing"
		else
			song = @getCurrentSong()
			if (song.song_details.type == "soundcloud")
				song.obj.play()
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
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			song.obj.pause()
		else if (song.song_details.type == "youtube")
			yt_player.pauseVideo()
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_pause()
		@state = 2
		@save('pause') if !update
			
		# set state		

	stop: (update) ->
		song = @getCurrentSong()
		try
			if (song.song_details.type == "soundcloud")
				song.obj.stop()
			else if (song.song_details.type == "youtube")
				yt_player.stopVideo()
			else if (song.song_details.type == "rdio")
				rdio_player.rdio_stop()
		@state = 0
		@save('stop') if !update

	seek: (percent) ->
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			song.obj.setPosition(song.song_details.duration * (percent / 100))
		else if (song.song_details.type == "youtube")
			yt_player.seekTo(yt_player.getDuration() * (percent / 100))
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_seek(song.song_details.duration * (percent / 100))

	setVolume: () ->
		song = @getCurrentSong()
		if (song.song_details.type == "soundcloud")
			song.obj.setVolume(@volume)
		else if (song.song_details.type == "youtube")
			yt_player.setVolume(@volume)
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_setVolume(@volume / 100)


	next: (update) ->
		if (@currentIndex + 1 < @playlist.length )
			@stop(true)
			@autoplay = false
			@currentIndex++
			@save('next', @currentIndex.toString()) if !update
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
		@playlist.push({
			song_details: song_details
		})
		@save('add', JSON.stringify(song_details)) if !update
		if (@playlist.length == 1)
			@loadSong () =>
				@setVolume @volume
				@play() #auto play
		if (@currentIndex + 2 == @playlist.length && (@state == 0 || @autoplay))
			@next()

	addFirst: (song_details, update) ->
		if (@playlist.length == 0)
			@add(song_details, update)
		else
			song_details.uuid = generateUUID()
			@playlist.splice(@currentIndex + 1, 0, {
				song_details: song_details
			})
			@next()
			@save "addFirst", JSON.stringify(song_details)

	remove: (index, update) ->
		if (index < @currentIndex)
			@playlist.splice(index, 1)
			@currentIndex--
		else if (index == @currentIndex)
			@stop(true) if not @autoplay
			@playlist.splice(index, 1)
			if (@currentIndex == @playlist.length)
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
		console.log "autoplay"
		if @lastRdioStation
			@stop()
			@autoplay = true
			rdio_player.rdio_play(@lastRdioStation)
			@setVolume @volume
			@play()
		else
			@state = 0
			@seek(100) # seek end of song
			@stop()

	loadSong: (cb) -> 
		if (cb == undefined)
			cb = () ->
		song = @getCurrentSong()
		if (!song)
			if (@currentIndex != 0)
				@currentIndex--
				song = @getCurrentSong()
			else
				$("body").css "background-image", ""
				return
		song_details = song.song_details

		$("body").css "background-image", "linear-gradient(rgba(0, 0, 0, 0.2),rgba(0, 0, 0, 0.2)),url('#{song_details.artwork_url || ""}')"
		$("body").css "background-size", "cover"
		$("body").css "background-attachment", "fixed"
		
		_this = @
		if (song_details.type == "soundcloud")
			SC.stream "/tracks/" + song_details.id, {
					whileplaying: (() ->
						_this.positionChanged "soundcloud", this.position),
					onload: (() ->
						if (this.readyState == 2)
							console.log "sc error"
							song.song_details.error = true
							_this.save("error", _this.currentIndex.toString())
							song.obj = null
							_this.next()
					),
					onplay: (() ->
						_this.setPlayState 1),
					onstop: (() ->
						_this.setPlayState 0),
					onpause: (() ->
						_this.setPlayState 2),
					onbufferchange: (() ->
						if (this.isBuffering) 
							_this.setPlayState 3
						else
							_this.setPlayState 1)
				}, (sound) ->
					song.obj = sound
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
						'onReady': (() ->
							yt_player.unMute()
							cb()),
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
			@lastRdioStation = song_details.radioKey
			@saveToDB("lastRdioStation")
			rdio_player.rdio_pause()
			cb()

	positionChanged: (type, position) ->
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
						scope.viewModal = true
						scope.firstModal = false
				if (scope.$$phase || scope.$root.$$phase) then openModal() else scope.$apply(openModal())
				@next()
			else if percent > 99.5
				@next()
	sendUpdate: (type, data) ->
		socket.emit 'update', {
			type: type,
			roomID: roomID,
			host: host,
			data: data
		}
	readUpdate: (update) ->
		if (update.type == "addFirst")
			@addFirst JSON.parse(update.data), true
		else if (update.type == "add")
			@add JSON.parse(update.data), true
		else if (update.type == "next")
			@next true
		else if (update.type == "prev")
			@prev true
		else if (update.type == "goTo")
			@goTo parseInt(update.data), true
		else if (update.type == "remove")
			@remove parseInt(update.data), true
		else if (update.type == "play")
			@state = 1
		else if (update.type == "pause")
			@state = 2
		else if (update.type == "stop")
			@state = 0
		else if (update.type == "move")
			data = JSON.parse(update.data)
			@move parseInt(data.from), parseInt(data.to), true
		else if (update.type == "error")
			@playlist[parseInt(update.data)].song_details.error = true
		scope = angular.element($("body")).scope()
		if (!scope.$$phase && !scope.$root.$$phase)
			scope.$apply()
		@saveToDB(update.type)
	save: (type, data) ->
		@sendUpdate type, data
		@saveToDB(type)
	saveToDB: (type) ->
		if (type == "add" || type == "addFirst" || type == "move" || type == "remove" || type == "error" || type == "playlist")
			stripped_playlist = _.map @playlist, (song) ->
				return _.omit(song, 'obj')

		if (type == "play")
			state = "1"
		else if (type == "pause")
			state = "2"
		else if (type == "stop")
			state = "0"
		else if (type == "state")
			state = JSON.stringify(@state)

		if (type == "next" || type == "prev" || type == "goTo" || type == "move" || type == "remove" || type == "index")
			currentIndex = JSON.stringify(@currentIndex)

		if (type == "lastRdioStation")
			lastRdioStation = @lastRdioStation

		if (type == "autoplay" || type == "next" || type == "goTo")
			autoplay = @autoplay

		playlistSettings = {
			currentIndex: currentIndex,
			playlist: stripped_playlist,
			volume: JSON.stringify(@volume),
			state: state,
			autoplay: JSON.stringify(autoplay),
			lastRdioStation: lastRdioStation
		}
		console.log(playlistSettings);
		$.post('/savePlaylist', { 
			playlistSettings: JSON.stringify(playlistSettings),
			roomID: roomID
		})





