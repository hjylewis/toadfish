# util.coffee

module.exports.encodeHtml = (str) ->
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/\//g,'&#47;')

