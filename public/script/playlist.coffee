#playlist.coffee



# obj:
# {
# 	obj
# 	song deatils
# }
class Playlist

	constructor: () ->
		@currentIndex = 0;
		@playlist = [];
		@state;

	play: () ->
		if (@playlist.length == 0)
			console.log "nothing here"
		else
			song = @playlist[@currentIndex]
			if (song.song_details.type == "soundcloud")
				song.obj.play();
				# set state

	pause: () ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.pause();
			# set state		

	stop: () ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.stop();

	seek: (percent) ->
		song = @playlist[@currentIndex]
		if (song.song_details.type == "soundcloud")
			song.obj.setPosition(song.song_details.duration * percent / 100);

	next: () ->
		if (@currentIndex + 1 < @playlist.length )
			@stop
			currentIndex++
			@loadSong
		else 
			@seek(100)
			# seek end of song

	prev: () ->
		if (@currentIndex > 0)
			@stop
			currentIndex--
			@loadSong
		else 
			@seek(0)

	add: (song_details) ->
		@playlist.push({
			song_details: song_details
		})
		if (@playlist.length == 1)
			@loadSong () =>
				@play() #auto play

	remove: (index) ->
		@playlist.splice(index, 1)
		if (index == @currentIndex)
			@loadSong

	loadSong: (cb) -> 
		song = @playlist[@currentIndex]
		song_details = song.song_details

		if (song_details.type == "soundcloud")
			if (song.obj)
				SC.sound = song.obj
				cb()
			else
				SC.stream "/tracks/" + song_details.id, (sound) ->
					song.obj = sound;
					SC.sound = sound;
					console.log(sound);
					cb()





playlist = new Playlist
