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


basePackage = null
npm.load {loglevel: 'silent'}, (err, npm) ->
  # args, silent, callback
  npm.commands.ls [], true, (err, thisPackage, thisPackageLight) ->
    basePackage = thisPackage

# BFS for a package of the given name and version
findPackage = (name, version) ->
  queue = [basePackage]
  while queue.length > 0
    current = queue.shift()
    return current if (current.name is name) and (current.version is version)
    queue.push(pak) for own n,pak of current.dependencies
  return null


app.get '/packages/:packageId', (req, res) ->
  [packageName, packageVersion] = req.params.packageId.split("@")

  p = findPackage packageName, packageVersion
  return res.send 404 if not p?

  find.docDirs p, (err, dirs) ->
    throw err if err?

    find.file dirs, packageName, (err, docFile, isMarkdown) ->
      throw err if err?
      return res.send "<< Couldn't find a readme file >>" if not docFile?

      if isMarkdown
        fs.readFile docFile, "utf8", (err, data) ->
          throw err if err?
          res.send markdown(data)
      else
        res.sendfile docFile

extractPackageMetadata = (pak) ->
  name: pak.name
  version: pak.version
  description: pak.description
  path: pak.path
  url: "/packages/#{pak.name}@#{pak.version}"
  author:
    name: pak.author?.name
    email: pak.author?.email
  homepage: pak.homepage
  bugsUrl: pak.bugs?.url
  licenses: pak.licenses

app.get '/project', (req, res) ->
  res.json
    basePackage: extractPackageMetadata(basePackage)
    dependencies: (extractPackageMetadata(pak) for name,pak of basePackage.dependencies)



http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
