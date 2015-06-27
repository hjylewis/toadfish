$('#createRoom').click () ->
	roomName = $('#createRoomName').val()
	$.ajax {
		url: '/createRoom',
		data: {'roomName': roomName},
		type: 'POST',
		success: (res) ->
			console.log res
	}