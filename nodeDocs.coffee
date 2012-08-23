###
Code to deal with the node.js docs, mostly downloading them. 
###

fs = require 'fs'
mkdirp = require 'mkdirp'
request = require 'request'
{exec} = require 'child_process'


module.exports.load = (cb) ->
  if fs.existsSync(nodeDocsDir)
    return cb(null, listDocFiles())

  downloadAndExtract (err) ->
    return cb(err) if err
    cb(null, listDocFiles())

listDocFiles = -> fs.readdirSync(nodeDocsDir)

getUserHome = ->
  if process.platform is 'win32'
    process.env['USERPROFILE']
  else
    process.env['HOME']

module.exports.dir = nodeDocsDir = "#{getUserHome()}/.superdoc/nodeDocs/#{process.version}"
nodeDownloadBaseUrl = "http://nodejs.org/dist"

haveLocalDocs = (cb) -> fs.exists(nodeDocsDir,cb)


downloadTarball = (cb) ->
  mkdirp nodeDocsDir, (err) ->
    return cb(err) if err?

    version = process.version

    distUrl = "#{nodeDownloadBaseUrl}/#{version}/node-#{version}.tar.gz"
    destFile = "#{nodeDocsDir}/node_src.tar.gz"

    console.log "Downloading node source (for docs) from to #{destFile}"

    destFileStream = fs.createWriteStream(destFile)
    req = request.get(distUrl).pipe(destFileStream)

    destFileStream.on 'error', (err) -> cb(err)
    destFileStream.on 'close', () ->
      cb(null, destFile)

downloadAndExtract = (cb) ->
  downloadTarball (err, localTarball) ->
    return cb(err) if err?

    mkdirp nodeDocsDir, (err) ->
      return cb(err) if err

      pathToDocsInTarball = "node-#{process.version}/doc/api/*.markdown"
      command = """
        tar xzf #{localTarball} --strip-components 3 #{pathToDocsInTarball} &&
        rm _toc.markdown &&
        rm all.markdown &&
        rm #{localTarball} """

      opts =
        cwd: nodeDocsDir
        stdio: 'inherit'

      exec command, opts, (err, stdout, stderr) ->
        console.log stdout
        console.log stderr
        cb(err)

