# Various small utility functions

fs = require 'fs'


fileExists = (filePath, callback) ->
  console.log filePath
  fs.stat filePath, (err, stat) ->
    throw err if err?
    callback stat?


module.exports =
  fileExists: fileExists
