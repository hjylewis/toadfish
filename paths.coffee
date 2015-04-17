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
    rdio.call 'search', {'query': query, 'types': 'Track'}, (err, msg) ->
      if err?
        console.error "rdio error:" + JSON.stringify(err)
        res.send []
      else 
        res.send msg.result.results

  app.post "/error", (req, res) ->
    console.error req.body.msg
    res.sendStatus 200

exports.start = start
