fs = require "fs"
async = require "async"
path = require "path"
_ = require "underscore"
npm = require "npm"

endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1


markdownExtension = "\\.(md|mkdn|mdown|markdown)$"
markdownExtensionRegex = new RegExp(markdownExtension)

exports.hasMarkdownExtension = (filename) ->
  return filename.match(markdownExtensionRegex)?

###
Recusrively list the contens of a package. Skip over subdirectories
which aren't likely to contain things which are part of the package
itself (like 'node_modules'). Returns an array of absolute file paths. 

packageDir: The base directory of the package
###
listFilesInPackage = (packageDir) ->
  files = []
  queue = [packageDir]

  ignore = /(node_modules$|\/\..*|vendor$|test$|deps$)/

  while queue.length > 0
    f = queue.shift()
    continue if f.match(ignore)

    files.push f
    if fs.statSync(f).isDirectory()
      queue.push(path.join(f, entry)) for entry in fs.readdirSync(f)

  return files


###
Find all the documentation files in the given package directory. 

packageDir: the package's base directory. 
packageName: the name of the package (used by the heuristic)
return: a list of paths relative to packageDir
###
exports.docFiles = (packageDir, packageName) ->
  allFiles = listFilesInPackage(packageDir)

  # a list of files to look for, with the highest-priority items first. 
  patterns =  [
    new RegExp "readme#{markdownExtension}"
    new RegExp "#{packageName}#{markdownExtension}"
    /index\.html$/
    /readme\.txt$/
    /readme/
    new RegExp "docs\\/.*#{markdownExtension}"
  ]
  patterns = _.flatten patterns

  docFiles = []
  for p in patterns
    for f in allFiles
      docFiles.push(f) if f.toLowerCase().match(p)

  docFiles = _.uniq docFiles
  # paths should be relative to the module dir
  docFiles = (f.substring(packageDir.length + 1, f.length) for f in docFiles)
  return docFiles

