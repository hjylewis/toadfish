log = console.log
express = require('express')
mongoose = require('mongoose')
middleware = require('../lib/middleware')
LocalSong = require('../models/localsong')
router = express.Router()

router.post "/:roomID/storeSongs", middleware.hostMiddleware, (req, res) ->
	roomID = req.param("roomID")
	console.log(req.body)
	res.send(200)



module.exports = router