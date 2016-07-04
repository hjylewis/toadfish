log = console.log
express = require('express')
mongoose = require('mongoose')
middleware = require('../lib/middleware')
LocalSong = require('../models/localsong')
router = express.Router()

router.post "/:roomID/storeSongs", middleware.hostMiddleware, (req, res) ->
	roomID = req.param("roomID")
	console.log(req.body);
	song = JSON.parse(req.body.song)
	LocalSong.findOne {
		roomID: roomID,
		title: song.title,
		album: song.album,
		artist: song.artist[0],
		genre: song.genre[0],
		year: song.year
	}, (err, existingSong) ->
		if (err)
			console.error "Error looking for song: " + JSON.stringify(err)
			return res.status(500).send err
		if (existingSong)
			return res.send { alreadyExists: true }
		LocalSong.create {
			roomID: roomID,
			title: song.title,
			album: song.album,
			artist: song.artist[0],
			genre: song.genre[0],
			year: song.year,
			url: song.path
		}, (err, newSong) ->
			if (err)
	          console.error "Error storing song: " + JSON.stringify(err)
	          res.status(500).send err
	        else
	          return res.send { songID: newSong._id }

router.delete "/:roomID", middleware.hostMiddleware, (req, res) ->
	roomID = req.param("roomID")
	LocalSong.find({roomID: roomID}).remove().exec()
	res.status(200).end()

router.get "/:roomID/search", middleware.roomMiddleware, (req, res) ->
	roomID = req.param("roomID")
	query = req.query.q
	page = parseInt(req.query.page) || 0
	page_length = parseInt(req.query.page_length)
	LocalSong.find(
        { $text : { $search : query } },
        { score : { $meta: "textScore" } }
    )
    .where('roomID').equals(roomID)
    .sort({ score : { $meta : 'textScore' } })
    .skip(page_length * page)
    .limit(page_length)
    .exec((err, results) ->
    	if (err)
	    	console.error err
	    	res.send []
	    	return
    	result = {
          collection: results || [],
          next_page: page + 1
        }
    	res.send result
    )

router.get "/autoplay/:songid", (req, res) ->
	songid = req.param("songid")
	LocalSong.findOne {_id: songid}, (err, song) ->
		if (err)
			console.error "Error finding song " + err
			return res.status(500).end()
		if (!song)
			return res.status(404).end()
		query = song.artist + ' ' + song.album + ' ' + song.genre
		LocalSong.find(
			{ $text : { $search : query } },
			{ score : { $meta: "textScore" } }
		)
		.where('roomID').equals(song.roomID)
		.where('_id').ne(songid)
		.sort({ score : { $meta : 'textScore' } })
		.limit(10)
		.exec((err, result) ->
			return res.status(500).end() if err?
			res.send result
		)

module.exports = router
