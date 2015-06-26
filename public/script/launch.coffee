$('#createRoom').click () ->
	roomid = $('createRoomID').val()
	$.ajax {
		url: '/createRoom',
		data: {'roomid': roomid},
		method: 'post'
		success: (res) ->
			console.log res
	}