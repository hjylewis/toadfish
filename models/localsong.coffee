mongoose = require('mongoose')

localsongSchema = new mongoose.Schema({ 
	room: String,
	title: String,
	album: String,
	artist: String,
	genre: String,
	year: String,
	img: { data: Buffer, contentType: String },
	URL: String
})

LocalSong = mongoose.model('LocalSong', localsongSchema)

module.exports = LocalSong