# paths.coffee

log = console.log
redis = require('redis')

start = (app) ->

  app.get "/", (request, result) ->
    result.render "index", {title: "Toadfish", layout: "views/layout.toffee"}

exports.start = start
