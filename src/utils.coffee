# Various small utility functions

fs = require 'fs'


fileExists = (filePath, callback) ->
  console.log filePath
  fs.stat filePath, (err, stat) ->
    throw err if err?
    callback stat?


# Expand any occureces of #{variables} by their definitions
# from the provided object.
#
# @param string [String] The input string to expand.
# @param definitions [Object] Values of the variables.
#
expandVars = (string, definitions) ->
  for name, value of definitions
    string = string.replace new RegEx "\#\{#{name}\}", value
  return string

module.exports =
  fileExists: fileExists
  expandVars: expandVars
