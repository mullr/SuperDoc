express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'

app = express()

public_dir = path.join(__dirname, 'public')

app.configure ->
  app.set 'port', process.env.PORT || 3000

  app.use mw for mw in [
    express.favicon()
    express.logger('dev')
    express.bodyParser()
    express.methodOverride()
    app.router
    express.static(public_dir)
  ]

app.configure 'development', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  fs.readFile path.join(public_dir, 'index.html'), 'utf8', (err, text) ->
    res.send text

http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
