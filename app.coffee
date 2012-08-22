express  = require 'express'
http     = require 'http'
path     = require 'path'
fs       = require 'fs'
markdown = require 'marked'
open     = require 'open'

connectAssets = require 'connect-assets'

mmm   = new require('mmmagic')
magic = new mmm.Magic(mmm.MAGIC_MIME)

util           = require './util'
packageLoading = require './packageLoading'


basePackage = null
packageLoading.getPackageInfoFor process.cwd(), (err, pkg) ->
  if err?
    console.log err
    process.exit 1

  basePackage = pkg
  startServer()

# BFS for a package of the given name and version
findPackage = (name, version) ->
  queue = [basePackage]
  while queue.length > 0
    current = queue.shift()
    return current if (current.name is name) and (current.version is version)
    queue.push(pak) for own n,pak of current.dependencies
  return null


app = express()

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'ejs'

  app.use mw for mw in [
    express.favicon "#{__dirname}/public/images/favicon.ico"
    express.logger('dev')
    express.bodyParser()
    express.methodOverride()
    app.router
    connectAssets
      src: "#{__dirname}/assets"
    express.static path.join(__dirname, 'public')
    express.static path.join(__dirname, 'node_modules/bootstrap/img')
    express.errorHandler()
  ]


startServer = ->
  http.createServer(app).listen app.get('port'), ->
    console.log "Express server listening on port " + app.get('port')
    open('http://localhost:3000')


###
Main page
###
app.get '/', (req, res) ->
  res.render 'index', {version: '0.0.1'}


###
Serve up package contents. A package is identified
by a 'name@verison' string. Anything after that indicates
a file in the package directory. Will render markdown files
to html; for everything else, it uses file magic to try to
at least get the content type correct. 

  Example url: /packages/express@3.0.0rc3/Readme.md
###
app.get /^\/packages\/(.*)/, (req, res) ->
  segments = req.params[0].split('/')

  [packageName, packageVersion] = segments.shift().split('@')
  relativePath = segments.join '/'

  pkg = findPackage packageName, packageVersion
  return res.send 404, "package not found" if not pkg?

  absolutePath = path.join pkg.path, relativePath

  if util.hasMarkdownExtension(relativePath)
    fs.readFile absolutePath, "utf8", (err, data) ->
      return res.send 404, "Couldn't read file" if err?
      res.send markdown(data)
  else
    magic.detectFile absolutePath, (err, mimeType) ->
      return res.send 404, "Couldn't detect file MIME type" if err?
      res.set 'Content-Type', mimeType
      res.sendfile absolutePath


###
Helper for generating the json to describe a package
###
packageMetadata = (pkg) ->
  packageUrl = (relativePath) -> "/packages/#{pkg.name}@#{pkg.version}/#{relativePath}"

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
    fileBaseUrl: packageUrl("")
    files: pkg.files

  return metadata

###
Get a json description of the current package and all of its direct
dependencies. Mostly the same as package.json, with the exception of
the added 'docs' field. 
###
app.get '/project', (req, res) ->
  deps = (pkg for own name, pkg of basePackage.dependencies)
  # the last one is bogus for some reason. 
  deps = deps.slice(0, deps.length-1)

  res.json
    basePackage: packageMetadata(basePackage)
    dependencies: (packageMetadata(pkg) for pkg in deps)

