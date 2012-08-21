
exports.markdownExtension = "\\.(md|mkdn|mdown|markdown)$"
markdownExtensionRegex = new RegExp(exports.markdownExtension)

exports.hasMarkdownExtension = (filename) ->
  return filename.match(markdownExtensionRegex)?
