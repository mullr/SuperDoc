fs = require "fs"
async = require "async"
path = require "path"
_ = require "underscore"
npm = require "npm"

# This is cribbed almost verbatim from https://github.com/russfrank/nd

module.exports.listModules = (global, cb) ->
  npm.load {loglevel: 'silent'}, (err, npm) ->

    npm.config.set('global',true) if global?
    args = []
    silent = true

    npm.commands.ls args, silent, cb

doBfs = (visitor, global, cb) ->
  npm.load {loglevel: 'silent'}, (err, npm) ->

    npm.config.set('global',true) if global?
    args = []
    silent = true

    npm.commands.ls args, silent, (err, thisModule, thisModuleLite) ->
      return cb(err) if err

      queue = [thisModule]

      while queue.length > 0
        node = queue.shift()
        node.global = global
        shouldStop = visitor(node)
        if shouldStop is 'stop'
          return cb(null, true)

        queue.push(mod) for own name,mod of node.dependencies

      cb(null, false)

###
Do a breadth-first search over all the locally installed modules, 
and then over all the global modules.  Call 'visitor' at each one. 
Return true from visitor to stop the search, or false to keep going.  
(May get some duplicates)
###
exports.moduleBfs = moduleBfs = (visitor, cb) ->
  doBfs visitor, false, (err, stoppedByVisitor) ->
    return cb(err) if err?
    if stoppedByVisitor
      return cb(null)

    doBfs visitor, true, (err) ->
      return cb(err) if err?
      cb(null)

###
Find the root directory for a given module
module: the module whose root directory we're trying to find
cb: continuation to respond to when complete
###
exports.root = root = (module, cb) ->
  modulePath = null

  moduleVisitor = (node) ->
    if node.name is module and node.path
      modulePath = node.path
      return 'stop'

  moduleBfs moduleVisitor, (err) ->
    return cb(err) if err?

    if modulePath is null
      cb new Error("module " + module + " not found")
    else
      cb null, modulePath

###
Find the doc directory for the module root supplied
npmModule: An npm module to search
cb:   Continuation to respond to when complete. Passed an array
      of possible doc directories. 
###
exports.docDirs = docDir = (npmModule, cb) ->
  root = npmModule.path
  dirsToTry = ["docs", "doc", "."]

  if npmModule.directories?.doc?
    dirsToTry.push npmModule.directories.doc
  else if npmModule.directories?
    dirsToTry.push npmModule.directories

  absoluteDirsToTry = (path.join(root,item) for item in dirsToTry)
  absoluteDirsToTry = _.uniq(absoluteDirsToTry)

  async.filter absoluteDirsToTry, path.exists, (result) ->
    cb null, result

###
Add various markdown extensions to the given arguments
arguments: arguments to add markdown extensions to
###
addMdExts = ->
  args = Array::slice.call(arguments)
  args.reduce ((memo, item) ->
    memo.concat [item + ".md", item + ".mkdn", item + ".mdown", item + ".markdown"]
  ), []



endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1

markdownExtensions = [".md", ".mkdn", ".mdown", ".markdown"]

exports.hasMarkdownExtension = (filename) ->
  for ext in markdownExtensions
    return true if endsWith(filename, ext)
  return false

# List everything recursively, but don't recurse into node_modules
listFilesInPackage = (packageDir) ->
  files = []
  queue = [packageDir]

  ignore = /(node_modules$|\/\..*|vendor$|test$)/

  while queue.length > 0
    f = queue.shift()
    continue if f.match(ignore)

    files.push f
    if fs.statSync(f).isDirectory()
      queue.push(path.join(f, entry)) for entry in fs.readdirSync(f)

  return files


exports.docFiles = (packageDir, packageName) ->
  allFiles = listFilesInPackage(packageDir)

  # a list of files to look for, with the highest-priority ones first. 
  patterns =  [
    /readme\.(md|mkdn|mdown|markdown)$/
    new RegExp("#{packageName}\\.$(md|mkdn|mdown|markdown)")
    /index\.html$/
    /readme\.txt$/
    /readme/
    /docs\/.*\.(md|mkdn|mdown|markdown|html)$/
  ]
  patterns = _.flatten patterns

  docFiles = []
  for p in patterns
    for f in allFiles
      docFiles.push(f) if f.toLowerCase().match(p)

  docFiles = _.uniq docFiles
  # paths should be relative to the module dir
  docFiles = (f.substring(packageDir.length + 1, f.length) for f in docFiles)
  console.log docFiles
  return docFiles


###
Try to find a documentation file. 

  dirs: the directories to look in. 
  packageName: the name of the package whose docs we're looking for
  cb: (err, {filePath: isMarkdown})
###
exports.file = file = (dirs, packageName, cb) ->

  fileBaseNames = ["index", packageName.toLowerCase(), "readme"]
  otherExtensions = [".html", ".txt", ""]

  markdownFilesToTry = (path.join(dir, baseName + ext) for dir in dirs for baseName in fileBaseNames for ext in markdownExtensions)
  otherFilesToTry    = (path.join(dir, baseName + ext) for dir in dirs for baseName in fileBaseNames for ext in otherExtensions)

  filesToTry = _.flatten [markdownFilesToTry, otherFilesToTry]

  async.filter filesToTry, path.exists, (filesThatExist) ->
    cb(null, filesThatExist)

