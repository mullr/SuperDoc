_ = require 'underscore'

exports.endsWith = endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1

exports.markdownExtension = "\\.(md|mkdn|mdown|markdown)$"
markdownExtensionRegex = new RegExp(exports.markdownExtension)

exports.hasMarkdownExtension = (filename) ->
  return filename.match(markdownExtensionRegex)?

