log = console.log
express = require('express')
mongoose = require('mongoose')
LocalSongFrame = require('toadfish-frame');
middleware = require('../lib/middleware')
LocalSong = require('../models/localsong')
router = express.Router()

router.post "/:roomID/storeSongs", middleware.hostMiddleware, (req, res) ->
	roomID = req.param("roomID")
	LocalSongFrame.fromFrame req, (err, song) ->
		if err
			console.error(err)
			res.status(500).end()
			return

		LocalSong.findOne {
			roomID: roomID,
			title: song.meta.title,
			album: song.meta.album,
			artist: song.meta.artist[0],
			genre: song.meta.genre[0],
			year: song.meta.year
		}, (err, existingSong) ->
			if (err)
				console.error "Error looking for song: " + JSON.stringify(err)
				return res.status(500).send err
			if (existingSong)
				return res.send { alreadyExists: true }
			LocalSong.create {
				roomID: roomID,
				title: song.meta.title,
				album: song.meta.album,
				artist: song.meta.artist[0],
				genre: song.meta.genre[0],
				year: song.meta.year,
				url: song.meta.path,
			}, (err, newSong) ->
				if (err)
					console.error "Error storing song: " + JSON.stringify(err)
					res.status(500).send err
				else
					if (song.image.length > 0)
						imageFilename = newSong._id + '.' + song.meta.imageFormat
						fileStream = req.gfs.createWriteStream({ filename: imageFilename })
						fileStream.end song.image, (err) ->
							newSong.artwork_url = '/localsong/' + roomID + '/image/' + imageFilename
							newSong.save (err) ->
								if (err)
									console.error "Error saving localsong: " + err
								return res.send { songID: newSong._id }

						fileStream.on 'error', (err) ->
							console.error err
							return res.send { songID: newSong._id }
						fileStream.on 'close', (file) ->
							console.log(file.filename + ' Written To DB');
					else
						return res.send { songID: newSong._id }

router.get "/:roomID/image/:songID", middleware.roomMiddleware, (req, res) ->
	options = {filename : req.param("songID")}
	req.gfs.exist options, (err, found) ->
		console.error(err) if (err)
		if (found)
			readstream = req.gfs.createReadStream(options)
			readstream.pipe(res);
		else
			res.status(404).end()

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
			console.log(results);
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
