express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
npm = require 'npm'
_ = require 'underscore'
markdown = require 'marked'


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
  res.render 'index', {version: '0.0.1'}


baseModule = null
npm.load {loglevel: 'silent'}, (err, npm) ->
  # args, silent, callback
  npm.commands.ls [], true, (err, thisModule, thisModuleLight) ->
    baseModule = thisModule

# BFS for a module of the given name and version
findModule = (name, version) ->
  queue = [baseModule]
  while queue.length > 0
    current = queue.shift()
    return current if (current.name is name) and (current.version is version)
    queue.push(mod) for own n,mod of current.dependencies
  return null


app.get '/modules/:moduleId', (req, res) ->
  [moduleName, moduleVersion] = req.params.moduleId.split("@")

  m = findModule moduleName, moduleVersion
  return res.send 404 if not m?

  find.docDirs m, (err, dirs) ->
    throw err if err?

    find.file dirs, moduleName, (err, docFile, isMarkdown) ->
      throw err if err?
      return res.send 404, "no doc found" if not docFile?

      if isMarkdown
        fs.readFile docFile, "utf8", (err, data) ->
          throw err if err?
          res.send markdown(data)
      else
        res.sendfile docFile


app.get '/modules', (req, res) ->
  result = []
  for own name,mod of baseModule.dependencies
    result.push
      name: mod.name
      version: mod.version
      path: mod.path
      url: "/modules/#{mod.name}@#{mod.version}"
      documentationFile: mod.documentationFile


  res.json
    modules: result



http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
