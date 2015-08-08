#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500
test = null
socket = io(window.location.origin)
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)

# TODO: state
# 0: pause
# 1: play
# 3: buffer

class Playlist
	constructor: (playlistSettings) ->
		@currentIndex = playlistSettings.currentIndex || 0
		@playlist = if playlistSettings.playlist then JSON.parse(playlistSettings.playlist) else []
		@state = playlistSettings.state || 0
		@autoplay = JSON.parse(playlistSettings.autoplay) || false
		socket.on 'update', (update) =>
			if update.socketID != socket.id
				@readUpdate(update)
		if @playlist.length > 0
			@loadSong()

	next: () ->
		if (@currentIndex + 1 < @playlist.length )
			@currentIndex++
			@loadSong()
			@state = 1

	prev: () ->
		if (@currentIndex > 0)
			@currentIndex--
			@loadSong()
			@state = 1

	goTo: (index) ->
		if (index >= 0 && index < @playlist.length)
			@currentIndex = index
			@loadSong()

	add: (song_details, update) ->
		@playlist.push({
			song_details: song_details
		})
		@save('add', JSON.stringify(song_details)) if !update
		if (@playlist.length == 1)
			@loadSong()
		if (@currentIndex + 2 == @playlist.length && @state == 0)
			@next()

	addFirst: (song_details) ->
		if (@playlist.length == 0)
			@add(song_details)
		else
			@playlist.splice(@currentIndex + 1, 0, {
				song_details: song_details
			})
			@next()

	remove: (index) ->
		test = index
		if (index < @currentIndex)
			@playlist.splice(index, 1)
			@currentIndex--
		else if (index == @currentIndex)
			@playlist.splice(index, 1)
			@loadSong()
		else
			@playlist.splice(index, 1)


	move: (from, to) ->
		@playlist.splice(to, 0, @playlist.splice(from, 1)[0])
		if (from < @currentIndex && to >= @currentIndex)
			@currentIndex--
		else if (from > @currentIndex && to <= @currentIndex)
			@currentIndex++
		else if (from == @currentIndex)
			@currentIndex = to
		
	loadSong: () -> 
		song = @playlist[@currentIndex]
		if (!song)
			if (@currentIndex != 0)
				@currentIndex--
				song = @playlist[@currentIndex]
			else
				$("body").css "background-image", ""
				return
		song_details = song.song_details

		$("body").css "background-image", "linear-gradient(rgba(0, 0, 0, 0.2),rgba(0, 0, 0, 0.2)),url('#{song_details.artwork_url || ""}')"
		$("body").css "background-size", "cover"
		$("body").css "background-attachment", "fixed"

	sendUpdate: (type, data) ->
		$.post('/sendUpdate', {
			type: type,
			roomID: roomID,
			host: host,
			data: data,
			socketID: socket.id
		})
	readUpdate: (update) ->
		if (ENV == 'dev')
			console.log update
		if (update.type == "addFirst")
			@addFirst JSON.parse(update.data)
		else if (update.type == "add")
			@add JSON.parse(update.data), true
		else if (update.type == "next")
			if (@autoplay)
				@autoplay = false
			@next()
		else if (update.type == "prev")
			@prev()
		else if (update.type == "goTo")
			if (@autoplay)
				@autoplay = false
			@goTo parseInt(update.data)
		else if (update.type == "remove")
			@remove parseInt(update.data)
		else if (update.type == "play")
			@state = 1
		else if (update.type == "pause")
			@state = 2
		else if (update.type == "stop")
			@state = 0
		else if (update.type == "move")
			data = JSON.parse(update.data)
			@move parseInt(data.from), parseInt(data.to)
		else if (update.type == "error")
			@playlist[parseInt(update.data)].song_details.error = true
		else if (update.type == "autoplay")
			@autoplay = update.data
		scope = angular.element($("body")).scope()
		if (!scope.$$phase && !scope.$root.$$phase)
			scope.$apply()
	save: (type, data) ->
		@sendUpdate type, data





