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

localsongSchema.index({ title: 'text', artist: 'text', album: 'text', genre: 'text' , year: 'text'}, 
	{name: 'localSongIndex', weights: { title: 10, artist: 8, album: 4, genre: 2}})

LocalSong = mongoose.model('LocalSong', localsongSchema)

module.exports = LocalSong