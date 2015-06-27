log = console.log
express = require('express')
mongoose = require('mongoose')
Room = require('../models/room')
router = express.Router()

router.get "/", (req, res) ->
  res.render "launch", {title: "Toadfish", layout: "views/layout.toffee"}

router.get "/demo", (req, res) ->
  res.render "room", {title: "Toadfish", layout: "views/layout.toffee"}

router.post "/createRoom", (req, res) ->
  db = req.db
  sessionID = req.sessionID
  roomName = req.body.roomName
  roomID = if roomName != "" then roomName.split(' ').join('-') else Math.random().toString(36).substr(2, 7)
  Room.find {roomID: roomID}, (err, rooms) ->
    if (rooms.length > 0)
      return res.send {
        alreadyExists: true
      }
    Room.create { roomName: req.body.roomName, roomID:  roomID, hostSessionID: sessionID}, (err, newRoom) ->
      if (err)
        console.error "Error creating room: " + JSON.stringify(err)
        res.status(500).send err
      else
        return res.send {
          roomID: roomID,
          alreadyExists: false
        }

router.post "/error", (req, res) ->
  console.error req.body.msg
  res.status(200).send("Error Logged")

module.exports = router
