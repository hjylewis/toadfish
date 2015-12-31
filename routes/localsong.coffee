log = console.log
express = require('express')
mongoose = require('mongoose')
middleware = require('../lib/middleware')
LocalSong = require('../models/localsong')
router = express.Router()

router.post "/:roomID/storeSongs", middleware.hostMiddleware, (req, res) ->
	roomID = req.param("roomID")
	song = JSON.parse(req.body.song)
	console.log(song)
	LocalSong.create {
		roomID: roomID,
		title: song.tags.title,
		album: song.tags.album,
		artist: song.tags.artist[0],
		genre: song.tags.genre[0],
		year: song.tags.year,
		url: song.url
	}, (err, newSong) ->
		if (err)
          console.error "Error storing song: " + JSON.stringify(err)
          res.status(500).send err
        else
          return res.status(200).end()

module.exports = router