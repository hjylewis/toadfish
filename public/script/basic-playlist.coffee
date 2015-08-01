#playlist.coffee

yt_player = null #for youtube, remember the player div
YT_TIME_INTERVAL = 500

socket = io('http://localhost:8000')
socket.on 'roomID', (msg) ->
	socket.emit('roomID', roomID)

# TODO: state
# 0: pause
# 1: play
# 3: buffer

class Playlist
	constructor: (currentIndex, playlist, volume, state) ->
		@currentIndex = currentIndex || 0
		@playlist = if playlist then JSON.parse(playlist) else []
		@state = state || 0
		socket.on 'update', (update) =>
			@readUpdate(update)
		if @playlist.length > 0
			@loadSong()

	next: () ->
		if (@currentIndex + 1 < @playlist.length )
			@currentIndex++
			@loadSong()

	prev: () ->
		if (@currentIndex > 0)
			@currentIndex--
			@loadSong()

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
		@playlist.splice(index, 1)
		if (index < @currentIndex)
			@currentIndex--
		else if (index == @currentIndex)
			@loadSong()

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
		song_details = song.song_details

		$("body").css "background-image", "linear-gradient(rgba(0, 0, 0, 0.2),rgba(0, 0, 0, 0.2)),url('#{song_details.artwork_url || ""}')"
		$("body").css "background-size", "cover"
		$("body").css "background-attachment", "fixed"

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
			@addFirst JSON.parse(update.data)
		else if (update.type == "add")
			@add JSON.parse(update.data), true
		else if (update.type == "next")
			@next()
		else if (update.type == "prev")
			@prev()
		else if (update.type == "goTo")
			@goTo update.data
		else if (update.type == "remove")
			@remove update.data
		else if (update.type == "play")
			@state = 1
		else if (update.type == "pause")
			@state = 2
		else if (update.type == "stop")
			@state = 0
		else if (update.type == "move")
			data = JSON.parse(update.data)
			@move data.from, data.to
		scope = angular.element($("body")).scope()
		if (!scope.$$phase && !scope.$root.$$phase)
			scope.$apply()
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





