# paths.coffee

log = console.log
redis = require('redis')
Rdio = require("./node_modules/rdio-simple/node/rdio");
config = require('./config');
rdio = new Rdio([config.rdio_cred.key, config.rdio_cred.secret]);



start = (app) ->

  app.get "/", (request, result) ->
    result.render "index", {title: "Toadfish", layout: "views/layout.toffee"}

  app.get "/rdio/search", (request, result) ->
    query = request.query.q
    rdio.call 'search', {'query': query, 'types': 'Track'}, (err, msg) ->
      if err?
        console.error "rdio error:" + JSON.stringify(err)
        result.send []
      else 
        result.send msg.result.results

  app.post "/error", (request, result) ->
    console.error request.body.msg
    result.send "Logged"

exports.start = start
