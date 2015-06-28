log = console.log
express = require('express')
mongoose = require('mongoose')
Room = require('../models/room')
router = express.Router()

router.get "/", (req, res) ->
  res.render "launch", {title: "Toadfish", layout: "views/layout.toffee"}

router.get "/demo", (req, res) ->
  res.render "room", {
    title: "Toadfish", 
    host: false,
    roomID: "", 
    playlistSettings: {}, 
    layout: "views/layout.toffee"
  }

router.post "/createRoom", (req, res) ->
  db = req.db
  sessionID = req.sessionID
  roomName = req.body.roomName
  roomID = if roomName != "" then roomName.replace(/\W/g, '').split(' ').join('-') else Math.random().toString(36).substr(2, 7)
  Room.find {roomID: roomID}, (err, rooms) ->
    if (rooms.length > 0)
      return res.send {
        alreadyExists: true
      }
    Room.create { roomName: req.body.roomName, roomID:  roomID, hostSessionID: sessionID }, (err, newRoom) ->
      if (err)
        console.error "Error creating room: " + JSON.stringify(err)
        res.status(500).send err
      else
        return res.send {
          roomID: roomID,
          alreadyExists: false
        }
router.post "/savePlaylist", (req, res) ->

  console.log req.body.roomID
  Room.findOne {$and: [{roomID: req.body.roomID}, {hostSessionID: req.sessionID}]}, (err, room) ->
    if (err)
      console.error "Error finding room to save to: " + JSON.stringify(err)
      return res.status(500).end()
    playlistSettings = JSON.parse(req.body.playlistSettings)
    room.playlistSettings.currentIndex = playlistSettings.currentIndex
    room.playlistSettings.playlist = JSON.stringify(playlistSettings.playlist)
    room.playlistSettings.volume = playlistSettings.volume
    room.save (err) ->
      if (err)
        console.error "Error saving playlist: " + JSON.stringify(err)
        return res.status(500).end()
      res.status(200).end()

router.get "/host/:roomID", (req, res) ->
  roomID = req.param("roomID")
  Room.findOne {roomID: roomID}, (err, room) ->
    if (err)
      console.error "Error finding room: " + JSON.stringify(err)
      return res.status(500).end()
    if (!room)
      return res.status(404).end()
    if (room.hostSessionID != req.sessionID)
      return res.redirect '/' + roomID
    res.render "room", {
      title: "Toadfish - " + roomID, 
      host: true,
      roomID: roomID, 
      playlistSettings: room.playlistSettings, 
      layout: "views/layout.toffee"
    }

router.get "/:roomID", (req, res) ->
  roomID = req.param("roomID")
  Room.findOne {roomID: roomID}, (err, room) ->
    if (err)
      console.error "Error finding room: " + JSON.stringify(err)
      return res.status(500).send err
    if (!room)
      return res.status(404).end() #render lost page
    if (room.hostSessionID == req.sessionID)
      return res.redirect '/host/' + roomID

    #Probably will have some different page here, that doesn't load stuff.
    res.render "room", {
      title: "Toadfish - " + roomID, 
      host: false,
      roomID: roomID, 
      playlistSettings: room.playlistSettings, 
      layout: "views/layout.toffee"
    }

router.post "/error", (req, res) ->
  console.error req.body.msg
  res.status(200).send("Error Logged")

module.exports = router
