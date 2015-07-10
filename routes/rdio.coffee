log = console.log
express = require('express')
router = express.Router()
request = require('request')
# Rdio = require("../node_modules/rdio-simple/node/rdio")
config = require('../config')

# rdio = new Rdio([config.rdio_cred.key, config.rdio_cred.secret]);
rdio_access_token = null

request({
    url: 'https://services.rdio.com/oauth2/token',
    method: 'POST',
    auth: {
      user: config.rdio_cred.client_id,
      pass: config.rdio_cred.client_secret
    },
    json: true,
    body: {
      grant_type: 'client_credentials'
    }
  }, (err, res, body) ->
    if (err)
      console.error "Error: Rdio Auth, " + err
    else
      rdio_access_token = body.access_token
      # refresh token?
      console.log body)

router.get "/search", (req, res) ->
  query = req.query.q
  page = parseInt(req.query.page) || 0
  page_length = parseInt(req.query.page_length)

  request({
    url: 'https://services.rdio.com/api/1/',
    method: 'POST',
    auth: {
      bearer: rdio_access_token
    },
    form: {'method': 'search', 'query': query, 'start': page * page_length, 'count': page_length, 'types': 'Track'}
    }, (err, response, body) ->
      if (err)
        console.error "rdio search error:" + JSON.stringify(err)
        res.send []
      else
        console.log body
        result = {
          collection: JSON.parse(body).result.results,
          next_page: page + 1
        }
        res.send result)
  
router.get "/playbackToken", (req, res) ->
  res.send ""
  # rdio.call 'getPlaybackToken', {'domain': 'localhost'}, (err, msg) ->
  #   if err?
  #     # console.error "rdio error getting playbackToken: " + JSON.stringify(err)
  #     res.send ""
  #   else
  #     res.send msg.result

module.exports = router
