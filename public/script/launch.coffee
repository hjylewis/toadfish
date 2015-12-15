submit = () ->
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