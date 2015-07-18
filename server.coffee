#!/usr/bin/env coffee
express = require("express")
params = require('express-params')
session = require('express-session')
cookieParser = require('cookie-parser')
mongoose = require('mongoose')
MongoStore = require('connect-mongo')(session)
Update = require('./models/update')
Room = require('./models/room')
stylus = require('stylus')
body_parser = require("body-parser")
coffee = require("coffee-middleware")
path = require("path")
http = require('http')
logger = require('morgan')

app = express()
params.extend(app)

routes = require('./routes/index')
rdio_routes = require('./routes/rdio')

app.use(cookieParser())

mongoose.connect('mongodb://localhost/toadfish')
db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once 'open', (callback) ->
	console.log "Toadfish DB connected"


app.use session({
  secret: 'keyboard cat',
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

# Make db accessible to the router
app.use (req, res, next) ->
    req.db = db
    next()

# Routers
app.use('/', routes)
app.use('/rdio', rdio_routes)


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

port = 8000

# For socket.io
server = http.Server(app);
io = require('socket.io')(server);

io.on 'connection', (socket) ->
	console.log("user connected")
	socket.emit('roomID')
	socket.on 'roomID', (roomID) ->
		socket.join(roomID)
	socket.on 'update', (obj) ->
		socket.broadcast.to(obj.roomID).emit('update', obj)
	# Update.find().sort({'_id': -1}).limit(1).find (err, doc) ->
	# 	lastUpdate = doc[0]
	# 	stream = Update.find().where('_id').gt(lastUpdate._id).tailable(true, { awaitdata: true, numberOfRetries: Number.MAX_VALUE }).stream()
	# 	stream.on 'data', (doc) ->
	# 		console.log "SOCKET"
	# 		socket.broadcast.to(doc.roomID).emit('update', doc);
	# 	stream.on 'error', (val) ->
	# 	    console.log('Error: %j', val)
	# 	stream.on 'end', () ->
	# 	    console.log('End of stream')

	socket.on 'disconnect', () ->
		console.log('user disconnected')
		# stream.destroy()


server.listen port, ->
	console.log "Listening on #{port}..."

cleanUpDB = () ->
	oneWeekAgo = new Date()
	oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
	Room.find({update: {"$lt": oneWeekAgo}}).remove().exec()
	setTimeout(cleanUpDB, 86400000) #one day

cleanUpDB()


