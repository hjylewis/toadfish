mongoose = require('mongoose')

roomSchema = new mongoose.Schema({ 
	roomName: String,
	roomID: String,
	hostSessionID: String,
	playlistSettings: {
		currentIndex: Number,
		playlist: String,
		volume: Number,
		state: Number,
		autoplay: String,
		lastRdioStation: String
	},
	update: Date,
})

Room = mongoose.model('Room', roomSchema)

module.exports = Room