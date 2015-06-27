mongoose = require('mongoose')

roomSchema = new mongoose.Schema({ 
	roomName: 'string',
	roomID: 'string',
	hostSessionID: 'string'
})

Room = mongoose.model('Room', roomSchema)

module.exports = Room