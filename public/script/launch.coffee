$('#createRoom').click () ->
	roomName = $('#createRoomName').val()
	$.ajax {
		url: '/createRoom',
		data: {'roomName': roomName},
		type: 'POST',
		success: (res) ->
			if (res.alreadyExists)
				$('#createWarning').attr('hidden',null)
			else
				window.location = '/host/' + res.roomID
	}
$('document').ready () ->
	if (rooms.length > 0)
		$('#list_open_rooms').parent().attr('hidden', null)
		_.each rooms, (room) ->
			display = room.roomName || room.roomID
			$('#list_open_rooms').append('<li><a href="/host/' + room.roomID + '">' + display + '</a></li>')