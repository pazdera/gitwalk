# Various small utility functions

fs = require 'fs'
minimatch = require 'minimatch'
child_process = require 'child_process'
logger = require './logger'

fileExists = (filePath, callback) ->
  #console.log filePath
  fs.stat filePath, (err, stat) ->
    callback stat?


# Expand any occureces of #{variables} by their definitions
# from the provided object.
#
# @param string [String] The input string to expand.
# @param definitions [Object] Values of the variables.
#
expandVars = (string, definitions) ->
  for name, value of definitions
    string = string.replace new RegExp("\#\{#{name}\}"), value
  return string


matchProc = (procStr) ->
  switch procStr.substr 0, 1
    when '/'
      return \
        name: 'file',
        args: [minimatch.makeRe procStr.substr 1]
    when '$'
      return \
        name: 'shell',
        args: []
    else
      return

runCommand = (command, cwd, callback) ->
    if !callback
      callback = cwd
      cwd = process.cwd()

    logger.debug "Running '#{command}'"
    proc = child_process.spawn '/bin/sh', ['-c', command],
      stdio: 'inherit'
      cwd: cwd

    proc.on 'error', callback
    proc.on 'close', (code) ->
      if code > 0
        logger.error "Command exited with non-zero: #{code}"

      callback()

module.exports = {fileExists, expandVars, matchProc, runCommand}
