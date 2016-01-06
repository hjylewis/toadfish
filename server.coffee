#!/usr/bin/env coffee
express = require('express')
compression = require('compression')
minify = require('express-minify');
params = require('express-params')
session = require('express-session')
cookieParser = require('cookie-parser')
mongoose = require('mongoose')
MongoStore = require('connect-mongo')(session)
Room = require('./models/room')
stylus = require('stylus')
body_parser = require('body-parser')
coffee = require('coffee-middleware')
favicon = require('serve-favicon')
path = require('path')
http = require('http')
logger = require('morgan')

app = express()
params.extend(app)

routes = require('./routes/index')
rdio_routes = require('./routes/rdio')
localsong_routes = require('./routes/localsong')

app.use(cookieParser())

# compress all requests
app.use(compression())
app.use(minify())
app.use(favicon(__dirname + '/public/favicon.ico'))

mongoose.connect(process.env.MONGOLAB_URI)
db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once 'open', (callback) ->
	console.log "Toadfish DB connected"


app.use session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  store: new MongoStore({ mongooseConnection: db })
})

app.use coffee {
	src: __dirname + '/public/script',
	bare: true
}

app.use(body_parser.json()) 
app.use(body_parser.urlencoded({ extended: false }))

app.use stylus.middleware {
	debug: true,
	force: true,
	src: __dirname + '/public',
	compress: true
}

app.use logger('dev')

app.use express.static 'public'

app.set 'view engine', 'toffee'
app.set('views', __dirname + '/views')

server = http.Server(app)
io = require('socket.io')(server)

# Make sockets accessible to the router
app.use (req, res, next) ->
    req.io = io
    next()

# Routers
app.use('/', routes)
app.use('/rdio', rdio_routes)
app.use('/localsong', localsong_routes)


app.get /.*/, (request, result) ->
  result.status(404).type('txt').send "404"

app.use (error, request, result, next) ->
	if error.status != 403
		next(error)
	else
  	# handle CSRF token errors here
    message = 'Session has expired or form tampered with.'
		console.error message
		console.error JSON.stringify request.body
		result.type('txt').status(403).send message


app.use (error, request, result, next) ->
	console.error error.stack
	result.status(500).type('txt').send 'Oops, it looks like something went'

port = process.env.PORT || 8000

# For socket.io

io.on 'connection', (socket) ->
	roomID = null
	console.log("user connected " + socket.id)
	socket.emit('roomID')
	socket.emit('reload')
	socket.on 'roomID', (rID) ->
		roomID = rID
		socket.join(roomID)
	socket.on 'disconnect', () ->
		console.log('user disconnected ' + socket.id)
		socket.leave(roomID) if roomID
		# Log out host
		Room.findOne {socketID: socket.id}, (err, room) ->
			if (!err && room)
				io.sockets.to(room.roomID).emit('no host')
				room.socketID = null
				room.save (err) ->
					if (err)
						console.error "Error saving logging out host: " + JSON.stringify(err)



server.listen port, ->
	console.log "Listening on #{port}..."

cleanUpDB = () ->
	console.log "Running room clean up..."
	oneWeekAgo = new Date()
	oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
	Room.find({update: {"$lt": oneWeekAgo}}).remove().exec()
	setTimeout(cleanUpDB, 86400000) #one day

cleanUpDB()


