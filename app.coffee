express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'

app = express()
public_dir = path.join(__dirname, 'public')

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'ejs'

  app.use mw for mw in [
    express.favicon()
    express.logger('dev')
    express.bodyParser()
    express.methodOverride()
    app.router
    require('connect-assets')()
    express.static(public_dir)
  ]

app.configure 'development', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index', {}

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
