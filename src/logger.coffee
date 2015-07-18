# A simple logger to report messages to the user on different levels
# and configurable verbosity.

chalk = require 'chalk'
config = require './config'

LEVELS =
  none: 0
  error: 1
  warn: 2
  info: 3
  debug: 4

logLevel = LEVELS[config.get 'logger:level']

logMsg = (level, label, msg) ->
  if not logLevel or logLevel >= level
    console.log "#{chalk.blue 'gitwalk'} #{label}: #{msg}"

exports.info = (msg) ->
  logMsg LEVELS.info, chalk.green('info'), msg

exports.warn = (msg) ->
  logMsg LEVELS.warn, chalk.black.bgYellow('warn'), msg

exports.error = (msg) ->
  logMsg LEVELS.error, chalk.black.bgRed('err!'), msg

exports.debug = (msg) ->
  logMsg LEVELS.debug, chalk.gray('dbg?'), msg
