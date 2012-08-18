express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
npm = require 'npm'
_ = require 'underscore'
markdown = require("node-markdown").Markdown


find = require './lib/find'

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

modules = []
moduleVisitor = (m) ->
  return if not m? or not m.path?
  find.docDirs m, (err, dirs) ->

    return if not dirs?

    find.file dirs, [], m.name, (err, docFile) ->
      m.documentationFile = docFile
      modules.push m

find.moduleBfs moduleVisitor, (err) ->


app.get '/modules/:moduleId', (req, res) ->
  [moduleName, moduleVersion] = req.params.moduleId.split("@")
  m = _.find modules, (m) -> m.name    is moduleName and
                             m.version is moduleVersion

  fs.readFile m.documentationFile, "utf8", (err, data) ->
    res.send markdown(data)


app.get '/modules', (req, res) ->
  result = []
  for m in modules
    result.push
      name: m.name
      version: m.version
      path: m.path
      url: "/modules/#{m.name}@#{m.version}"
      documentationFile: m.documentationFile

  res.json
    modules: result



http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
