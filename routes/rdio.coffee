log = console.log
express = require('express')
router = express.Router()
Rdio = require("../node_modules/rdio-simple/node/rdio");
config = require('../config');

rdio = new Rdio([config.rdio_cred.key, config.rdio_cred.secret]);

router.get "/search", (req, res) ->
  query = req.query.q
  page = parseInt(req.query.page) || 0
  page_length = parseInt(req.query.page_length)
  rdio.call 'search', {'query': query, 'start': page * page_length, 'count': page_length, 'types': 'Track'}, (err, msg) ->
    if err?
      # DONT COMMIT THIS
      # console.error "rdio search error:" + JSON.stringify(err)
      res.send []
    else 
      result = {
        collection: msg.result.results,
        next_page: page + 1
      }
      res.send result
router.get "/playbackToken", (req, res) ->
  rdio.call 'getPlaybackToken', {'domain': 'localhost'}, (err, msg) ->
    if err?
      # console.error "rdio error getting playbackToken: " + JSON.stringify(err)
      res.send ""
    else
      res.send msg.result

module.exports = router
