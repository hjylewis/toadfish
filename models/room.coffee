mongoose = require('mongoose')

roomSchema = new mongoose.Schema({ 
	roomName: String,
	roomID: String,
	hostSessionID: String,
	socketID: String,
	playlistSettings: {
		currentIndex: Number,
		playlist: String,
		volume: Number,
		state: Number,
		autoplay: String,
	},
	enabled: {
		soundcloud: Boolean,
		youtube: Boolean,
		rdio: Boolean,
		local: Boolean
	},
	banned: [String],
	update: Date
})

Room = mongoose.model('Room', roomSchema)

module.exports = Room