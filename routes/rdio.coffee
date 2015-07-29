log = console.log
express = require('express')
router = express.Router()
request = require('request')
config = require('../config')

rdio_access_token = null

getAccess = () ->
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
        setTimeout(getAccess, body.expires_in * 900))

rdioRequest = (data, cb) ->
  request({
    url: 'https://services.rdio.com/api/1/',
    method: 'POST',
    auth: {
      bearer: rdio_access_token
    },
    form: data
    }, cb)

getAccess()

router.get "/search", (req, res) ->
  query = req.query.q
  page = parseInt(req.query.page) || 0
  page_length = parseInt(req.query.page_length)
  rdioRequest {'method': 'search', 'query': query, 'start': page * page_length, 'count': page_length, 'types': 'Track'}, (err, response, body) ->
      if (err)
        console.error "rdio search error:" + JSON.stringify(err)
        res.send []
      else
        result = {
          collection: if JSON.parse(body).result then JSON.parse(body).result.results else [],
          next_page: page + 1
        }
        res.send result


router.get "/playbackToken", (req, res) ->
  rdioRequest {'method': 'getPlaybackToken', 'domain': 'localhost'}, (err, response, body) ->
    if err?
      console.error "rdio error getting playbackToken: " + JSON.stringify(err)
      res.send ""
    else
      res.send JSON.parse(body).result

module.exports = router
