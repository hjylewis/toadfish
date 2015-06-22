# paths.coffee

log = console.log
redis = require('redis')
Rdio = require("./node_modules/rdio-simple/node/rdio");
config = require('./config');
rdio = new Rdio([config.rdio_cred.key, config.rdio_cred.secret]);


start = (app) ->

  app.get "/", (req, res) ->
    res.render "index", {title: "Toadfish", layout: "views/layout.toffee"}

  app.get "/rdio/search", (req, res) ->
    query = req.query.q
    page = parseInt(req.query.page) || 0
    page_length = parseInt(req.query.page_length)
    rdio.call 'search', {'query': query, 'start': page * page_length, 'count': page_length, 'types': 'Track'}, (err, msg) ->
      if err?
        console.error "rdio search error:" + JSON.stringify(err)
        res.send []
      else 
        result = {
          collection: msg.result.results,
          next_page: page + 1
        }
        res.send result
  app.get "/rdio/playbackToken", (req, res) ->
    rdio.call 'getPlaybackToken', {'domain': 'localhost'}, (err, msg) ->
      if err?
        console.error "rdio error getting playbackToken: " + JSON.stringify(err)
        res.send ""
      else
        res.send msg.result

  app.post "/error", (req, res) ->
    console.error req.body.msg
    res.status(200).send("Error Logged")

exports.start = start
