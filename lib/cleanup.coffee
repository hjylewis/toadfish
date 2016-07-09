Room = require('../models/room')
LocalSong = require('../models/localsong')


module.exports.cleanUpDB = (gfs) ->
  	console.log "Running room clean up..."
  	oneWeekAgo = new Date()
  	oneWeekAgo.setDate(oneWeekAgo.getDate() - 1)
  	Room.find({update: {"$lt": oneWeekAgo}}).exec (err, rooms) ->
      rooms.forEach (room) ->
        song_query = LocalSong.find {roomID: room.roomID}, (err, songs) ->
          songs.forEach (song) ->
            if (song.artwork_url)
              filename = song.artwork_url.match(/\/image\/(.+)/)[1]
              options = {filename : filename}
              gfs.exist options, (err, found) ->
                if (err)
                  return console.error err
                if (found)
                  gfs.remove options, (err) ->
                    if (err)
                      return console.error err
            song.remove()
        room.remove()
