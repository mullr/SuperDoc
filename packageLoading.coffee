npm  = require 'npm'
fs   = require 'fs'
path = require 'path'
_    = require 'underscore'

util = require './util'
###
Load package info for the given directory. Packages are normal
npm objects

Callback is (err, basePackage)
###
module.exports.getPackageInfoFor = (baseDir, cb) ->
  npm.load {loglevel: 'silent'}, (err, npm) ->
    npm.dir = baseDir
    # args, silent, callback
    npm.commands.ls [], true, (err, basePackage, basePackageLight) ->
      if not basePackage.name?
        return cb "Couldn't find a node_modules directory"

      deps = (pkg for own name,pkg of basePackage.dependencies)
      allPackages = [basePackage].concat(deps)
      for pkg in allPackages
        pkg.files = listFilesInPackage(pkg.path)

      cb(null, basePackage)


###
Recusrively list the contens of a package. Skip over subdirectories
which aren't likely to contain things which are part of the package
itself (like 'node_modules'). Returns an array of relative file paths. 

packageDir: The base directory of the package
###
listFilesInPackage = (packageDir) ->
  files = []
  queue = [packageDir]

  ignore = /(node_modules$|\/\..*|vendor$|test$|deps$)/

  while queue.length > 0
    f = queue.shift()
    continue if f.match(ignore)

    if fs.statSync(f).isDirectory()
      files.push f + "/"
      queue.push(path.join(f, entry)) for entry in fs.readdirSync(f)
    else
      files.push f

  # paths should be relative to the module dir
  files = (f.substring(packageDir.length + 1, f.length) for f in files)

  # remove the first (empty) element, which is the baseDir
  files.shift()

  return files


