express = require 'express'
http = require 'http'
path = require 'path'
fs = require 'fs'
npm = require 'npm'
_ = require 'underscore'
markdown = require 'marked'
async = require 'async'
open = require 'open'

mmm = new require('mmmagic')
magic = new mmm.Magic(mmm.MAGIC_MIME)


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
    require('connect-assets') {src: "#{__dirname}/assets"}
    express.static(public_dir)
  ]

app.configure 'development', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index', {version: '0.0.1'}

doneLoading = false
basePackage = null
npm.load {loglevel: 'silent'}, (err, npm) ->
  npm.dir = process.cwd()
  # args, silent, callback
  npm.commands.ls [], true, (err, thisPackage, thisPackageLight) ->
    if not thisPackage.name?
      console.log "Couldn't find a node_modules directory"
      process.exit 1

    basePackage = thisPackage

    deps = (pkg for own name,pkg of basePackage.dependencies)
    allPackages = [basePackage].concat(deps)
    for pkg in allPackages
      console.log pkg.name
      pkg.documentationFiles = find.docFiles(pkg.path, pkg.name)

    doneLoading = true
    startServer()

# BFS for a package of the given name and version
findPackage = (name, version) ->
  queue = [basePackage]
  while queue.length > 0
    current = queue.shift()
    return current if (current.name is name) and (current.version is version)
    queue.push(pak) for own n,pak of current.dependencies
  return null

findDocFilesForPackage = (pak, cb) ->
  find.docDirs pak, (err, dirs) ->
    return cb(err) if err?

    find.file dirs, pak.name, (err, docFiles) ->
      return cb(err) if err?

      pak.documentationFiles = []
      for f in docFiles
        # Put relative paths in here; the +1 knocks off a slash
        pak.documentationFiles.push f.substring(pak.path.length + 1, f.length)

      cb(null)


app.get /^\/packages\/(.*)/, (req, res) ->
  segments = req.params[0].split('/')

  [packageName, packageVersion] = segments.shift().split('@')
  relativePath = segments.join '/'

  pkg = findPackage packageName, packageVersion
  return res.send 404, "package not found" if not pkg?

  absolutePath = path.join pkg.path, relativePath

  if find.hasMarkdownExtension(relativePath)
    fs.readFile absolutePath, "utf8", (err, data) ->
      return res.send 404, "Couldn't read file" if err?
      res.send markdown(data)
  else
    console.log magic
    magic.detectFile absolutePath, (err, mimeType) ->
      throw err if err?
      res.set 'Content-Type', mimeType
      res.sendfile absolutePath

extractPackageMetadata = (pkg) ->

  docUrl = (relativePath) -> "/packages/#{pkg.name}@#{pkg.version}/#{relativePath}"
  otherDocs = pkg.documentationFiles.slice(1, pkg.documentationFiles.length)

  metadata =
    name: pkg.name
    version: pkg.version
    description: pkg.description
    path: pkg.path
    author:
      name: pkg.author?.name
      email: pkg.author?.email
    homepage: pkg.homepage
    bugsUrl: pkg.bugs?.url
    licenses: pkg.licenses
    docs: ({name: p, url: docUrl(p)} for p in pkg.documentationFiles)

  return metadata

app.get '/project', (req, res) ->
  deps = (pkg for own name, pkg of basePackage.dependencies)
  # the last one is bogus for some reason. 
  deps = deps.slice(0, deps.length-1)

  res.json
    basePackage: extractPackageMetadata(basePackage)
    dependencies: (extractPackageMetadata(pkg) for pkg in deps)


startServer = ->
  http.createServer(app).listen app.get('port'), ->
    console.log "Express server listening on port " + app.get('port')
    open('http://localhost:3000')
