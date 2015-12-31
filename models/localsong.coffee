mongoose = require('mongoose')

localsongSchema = new mongoose.Schema({ 
	roomID: String,
	title: String,
	album: String,
	artist: String,
	genre: String,
	year: String,
	# img: { data: Buffer, contentType: String },
	url: String
})

LocalSong = mongoose.model('LocalSong', localsongSchema)

module.exports = LocalSong