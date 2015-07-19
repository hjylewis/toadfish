#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500
yt_obj = {artwork_url: "https://i.ytimg.com/vi/ih2xubMaZWI/hqdefault.jpg", id: "ih2xubMaZWI", permalink_url: "https://www.youtube.com/watch?v=ih2xubMaZWI", title: "OMFG - Hello",type: "youtube"}
sc_obj = {artwork_url: "https://i1.sndcdn.com/artworks-000110807035-1bxk4l-t500x500.jpg", duration: 226371, id: 178220277, permalink_url: "https://soundcloud.com/alexomfg/omfg-hello", title: "OMFG - Hello", type: "soundcloud", user: "OMFG"}
rd_obj = {artist: "OMFG", artwork_url: "http://img02.cdn2-rdio.com/album/8/3/5/000000000050f538/2/square-600.jpg", duration: 226, id: "t60862619", permalink_url: "http://rd.io/x/QitB__PE/", title: "Hello", type: "rdio"}

socket = io('http://localhost:8000')
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)

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
		socket.on 'update', (update) =>
			@readUpdate(update)

	load: (currentIndex, playlist, volume) ->
		@currentIndex = currentIndex || 0
		@playlist = if playlist then JSON.parse(playlist) else []
		@volume = volume || 100
		if @playlist.length > 0
			@loadSong () =>
				@setVolume @volume
				@play() #auto play

	play: () ->
		if (@playlist.length == 0)
			console.log "nothing here"
		else if @state == 1
			console.log "Already playing"
		else
			song = @playlist[@currentIndex]
			if (song.song_details.type == "soundcloud")
				song.obj.play()
			else if (song.song_details.type == "youtube")
				yt_player.playVideo()
				@positionChanged "youtube"
			else if (song.song_details.type == "rdio")
				rdio_player.rdio_play()
			# set state


	pause: () ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.pause()
		else if (song.song_details.type == "youtube")
			yt_player.pauseVideo()
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_pause()
		# set state		

	stop: () ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.stop()
		else if (song.song_details.type == "youtube")
			yt_player.stopVideo()
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_stop();

	seek: (percent) ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.setPosition(song.song_details.duration * (percent / 100))
		else if (song.song_details.type == "youtube")
			yt_player.seekTo(yt_player.getDuration() * (percent / 100))
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_seek(song.song_details.duration * (percent / 100))

	setVolume: (percent) ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.setVolume(percent)
		else if (song.song_details.type == "youtube")
			yt_player.setVolume(percent)
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_setVolume(percent / 100)
		@volume = percent;


	next: (update) ->
		if (@currentIndex + 1 < @playlist.length )
			@stop()
			@currentIndex++
			@loadSong () => #might wanna make is so it doesn't play if player is paused
				@setVolume @volume
				@play()
		else 
			@state = 0
			@seek(100) # seek end of song
			@stop()
		@save('next', @currentIndex.toString()) if !update

	prev: (update) ->
		if (@currentIndex > 0)
			@stop()
			@currentIndex--
			@loadSong () =>
				@setVolume @volume
				@play()
		else 
			@seek(0)
		@save('prev', @currentIndex.toString()) if !update

	goTo: (index, update) ->
		if (index >= 0 && index < @playlist.length)
			@stop()
			@currentIndex = index
			@loadSong () =>
				@setVolume @volume
				@play()
			@save('goTo', @currentIndex.toString()) if !update

	add: (song_details, update) ->
		@playlist.push({
			song_details: song_details
		})
		if (@playlist.length == 1)
			@loadSong () =>
				@setVolume @volume
				@play() #auto play
		@save('add', JSON.stringify(song_details)) if !update

	addFirst: (song_details, update) ->
		if (@playlist.length == 0)
			@add(song_details, update)
		else
			@playlist.splice(@currentIndex + 1, 0, {
				song_details: song_details
			})
			@next(true)
			@save "addFirst", JSON.stringify(song_details)

	remove: (index, update) ->
		@playlist.splice(index, 1)
		if (index == @currentIndex)
			@stop()
			@loadSong () =>
				@setVolume @volume
				@play() #auto play
		@save('remove', index.toString()) if !update

	setPlayState: (state) =>
		scope = angular.element($("body")).scope()
		if (scope.$$phase || scope.$root.$$phase)
			scope.playlist.state = state
		else
			scope.$apply(scope.playlist.state = state)

	loadSong: (cb) -> 
		if (cb == undefined)
			cb = () ->
		song = @playlist[@currentIndex]
		song_details = song.song_details

		$("body").css "background-image", "url('#{song_details.artwork_url || ""}')"
		$("body").css "background-size", "cover"
		$("body").css "background-attachment", "fixed"
		
		_this = @
		if (song_details.type == "soundcloud")
			if (song.obj)
				SC.sound = song.obj
				cb()
			else
				SC.stream "/tracks/" + song_details.id, {
						whileplaying: (() ->
							_this.positionChanged "soundcloud", this.position),
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
			rdio_player.rdio_pause()
			cb()

	positionChanged: (type, position) ->
		if (type == @playlist[@currentIndex].song_details.type && @state != 0)

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
				percent = (position / @playlist[@currentIndex].song_details.duration) * 100
			if percent > 99.5
				@next()
	sendUpdate: (type, data) ->
		socket.emit 'update', {
			type: type,
			roomID: roomID,
			host: host,
			data: data
		}
	readUpdate: (update) ->
		console.log update
		if (update.type == "addFirst")
			@addFirst JSON.parse(update.data), true
		else if (update.type == "add")
			@add JSON.parse(update.data), true
		else if (update.type == "next")
			@next true
		else if (update.type == "prev")
			@prev true
		else if (update.type == "goTo")
			@goTo update.data, true
		else if (update.type == "remove")
			@remove update.data, true
	save: (type, data) ->
		@sendUpdate type, data
		if host
			stripped_playlist = _.map @playlist, (song) ->
				return _.omit(song, 'obj')
			playlistSettings = {
				currentIndex: @currentIndex,
				playlist: stripped_playlist,
				volume: @volume
			}
			$.post('/savePlaylist', { 
				playlistSettings: JSON.stringify(playlistSettings),
				roomID: roomID
			})





