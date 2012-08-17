fs = require "fs"
async = require "async"
path = require "path"
_ = require "underscore"
npm = require "npm"

# This is cribbed almost verbatim from https://github.com/russfrank/nd

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


###
Try to find a file matching the given query and give its contents
to `cb`

dirs:   array of directories to search in
args:   arguments of query
module: name of the module
cb:   continuation to respond to when complete

<< from nd docs >> 
For example, if we type

$ nd npm cli

We will get npm/doc/cli/index.md. So, if additional arguments (besides the
module name) are provided, we try to find a file which is more specific: we'll
look for module/arg1/arg2/index.md, module/arg1/arg2/arg2.md, and
module/arg1/arg2.md. This allows us to be flexible about the organization of
documentation within modules.
###
exports.file = file = (dirs, args, module, cb) ->
  filesToTry = []

  for d in dirs
    base = path.join(d, path.join.apply(null, args))

    # for supporting module/args*.md
    filesToTry.push addMdExts(path.join(base))
    
    # for supporting module/args*/index.md
    filesToTry.push addMdExts(path.join(base, "index"))

    if args and args.length isnt 0
      # for supporting module/args*/lastarg.md
      filesToTry.push addMdExts(path.join(base, args[args.length - 1]))

    else
      # for supporting module/docs/modulename.md
      filesToTry.push addMdExts(path.join(base, module))
      
      # for supporting README.md
      filesToTry.push addMdExts(path.join(base, "Readme"),
                                path.join(base, "ReadMe"),
                                path.join(base, "readme"),
                                path.join(base, "README"))


  filesToTry.push path.join(base, 'index.html')
  filesToTry.push path.join(base, 'README')

  filesToTry = _.flatten filesToTry
  
  # find the first of the `tries` array which actually exists, and return it
  async.detectSeries filesToTry, path.exists, (result) ->
    if result
      cb null, result
    else
      cb new Error("no markdown files found matching query")

