Room = require('../models/room')

middleware = {}

middleware.hostMiddleware = (req, res, next) ->
  roomID = req.param("roomID")
  Room.findOne {roomID: roomID}, (err, room) ->
      if (err)
        console.error "Error finding room: " + JSON.stringify(err)
        return res.status(500).end()
      if (!room)
        return res.status(404).end()
      if (room.hostSessionID != req.sessionID)
        return res.status(403).end()
      req.room = room
      next()
      return

middleware.roomMiddleware = (req, res, next) ->
  roomID = req.param("roomID")
  Room.findOne {roomID: roomID}, (err, room) ->
    if (err)
      console.error "Error finding room: " + JSON.stringify(err)
      return res.status(500).send err
    if (!room)
      return res.status(404).end() #render lost page
    req.room = room
    next()
    return

module.exports = middleware
