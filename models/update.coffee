mongoose = require('mongoose')

updateSchema = new mongoose.Schema({ 
	roomID: String,
	type: String,
	data: String,
	host: Boolean
},{ capped: { size: 1024 } })

Update = mongoose.model('Update', updateSchema)

module.exports = Update