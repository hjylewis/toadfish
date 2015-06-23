#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500
yt_obj = {artwork_url: "https://i.ytimg.com/vi/ih2xubMaZWI/hqdefault.jpg", id: "ih2xubMaZWI", permalink_url: "https://www.youtube.com/watch?v=ih2xubMaZWI", title: "OMFG - Hello",type: "youtube"}
sc_obj = {artwork_url: "https://i1.sndcdn.com/artworks-000110807035-1bxk4l-t500x500.jpg", duration: 226371, id: 178220277, permalink_url: "https://soundcloud.com/alexomfg/omfg-hello", title: "OMFG - Hello", type: "soundcloud", user: "OMFG"}
rd_obj = {artist: "OMFG", artwork_url: "http://img02.cdn2-rdio.com/album/8/3/5/000000000050f538/2/square-600.jpg", duration: 226, id: "t60862619", permalink_url: "http://rd.io/x/QitB__PE/", title: "Hello", type: "rdio"}


# TODO: state
# 0: pause
# 1: play
# 3: buffer

class Playlist

	constructor: () ->
		@currentIndex = 0;
		@playlist = [];
		@state;
		@volume = 100;

	play: () ->
		if (@playlist.length == 0)
			console.log "nothing here"
		else
			song = @playlist[@currentIndex]
			if (song.song_details.type == "soundcloud")
				song.obj.play()
			else if (song.song_details.type == "youtube")
				yt_player.playVideo()
				youtubePositionChange()
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
			song.obj.setPosition(song.song_details.duration * percent / 100)
		else if (song.song_details.type == "youtube")
			yt_player.seekTo(yt_player.getDuration() * percent / 100)
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_seek(song.song_details.duration * percent / 100)

	setVolume: (percent) ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.setVolume(percent)
		else if (song.song_details.type == "youtube")
			yt_player.setVolume(percent)
		else if (song.song_details.type == "rdio")
			rdio_player.rdio_setVolume(percent / 100)
		@volume = percent;


	next: () ->
		if (@currentIndex + 1 < @playlist.length )
			@stop()
			@currentIndex++
			@loadSong () => #might wanna make is so it doesn't play if player is paused
				@setVolume @volume
				@play()
		else 
			@seek(100) # seek end of song

	prev: () ->
		if (@currentIndex > 0)
			@stop()
			@currentIndex--
			@loadSong () =>
				@setVolume @volume
				@play()
		else 
			@seek(0)

	add: (song_details) ->
		@playlist.push({
			song_details: song_details
		})
		if (@playlist.length == 1)
			@loadSong () =>
				@setVolume @volume
				@play() #auto play

	remove: (index) ->
		@playlist.splice(index, 1)
		if (index == @currentIndex)
			@stop()
			@loadSong () =>
				@setVolume @volume
				@play() #auto play

	loadSong: (cb) -> 
		if (cb == undefined)
			cb = () ->
		song = @playlist[@currentIndex]
		song_details = song.song_details
		if (song_details.type == "soundcloud")
			if (song.obj)
				SC.sound = song.obj
				cb()
			else
				SC.stream "/tracks/" + song_details.id, {
						whileplaying: () ->
							positionChanged this.position, "soundcloud"
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
						'onReady': () ->
							yt_player.unMute()
							cb()
					}
		        })
			else
				yt_player.loadVideoById(song_details.id)
				cb()
		else if (song_details.type == "rdio")
			rdio_player.rdio_play(song_details.id)
			rdio_player.rdio_pause()
			cb()

youtubePositionChange = () ->
	positionChanged yt_player.getCurrentTime(), "youtube"
	if (playlist.playlist[playlist.currentIndex].song_details.type == "youtube")
		setTimeout((() ->
			if (yt_player.getPlayerState() == 1 || yt_player.getPlayerState() == 3)
				youtubePositionChange()
			), YT_TIME_INTERVAL)

positionChanged = (position, type) ->
	#if (type == playlist.playlist[playlist.currentIndex].song_details.type)
		# update graphics
		# console.log position




playlist = new Playlist
