# util.coffee

module.exports.encodeHtml = (str) ->
    return String(str).replace(/[^0-9a-zA-Z$\-_.+!*'(),]/g, "")

