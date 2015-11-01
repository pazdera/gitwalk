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
      cwd: cwd
      #stdio: 'inherit'

    proc.stdout.on 'data', (data) ->
      for line in data.toString('utf8').split '\n'
        logger.info line, getCommandName command if line.length > 0

    proc.stderr.on 'data', (data) ->
      for line in data.toString('utf8').split '\n'
        logger.error line, getCommandName command if line.length > 0

    proc.on 'error', callback
    proc.on 'close', (code) ->
      if code > 0
        logger.error "Command exited with non-zero: #{code}"

      callback()

isArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

removeExtension = (f) -> f.replace /\.[^/.]+$/, ""

getCommandName = (command) ->
  tokens = command.split /\s+/
  for token in tokens
    if '=' in token
      continue
    else
      return token

  return tokens[0]


module.exports = {fileExists, expandVars, matchProc, runCommand, isArray,
                  removeExtension, getCommandName}
