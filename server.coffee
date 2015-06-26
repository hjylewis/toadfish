#!/usr/bin/env coffee
express = require("express")
params = require('express-params')
session = require('express-session')
cookieParser = require('cookie-parser')
mongoose = require('mongoose')
MongoStore = require('connect-mongo')(session)
stylus = require('stylus')
body_parser = require("body-parser")
coffee = require("coffee-middleware")
path = require("path")
http = require('http')
logger = require('morgan')

app = express()
params.extend(app)


paths = require("./paths")

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


paths.start(app)


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
app.listen port, ->
	console.log "Listening on #{port}..."
