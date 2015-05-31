# printing functions for the terminal

chalk = require 'chalk'

logMsg = (level, msg) ->
  console.log "#{chalk.blue 'gitwalk'} #{level}: #{msg}"

exports.info = (msg) ->
  logMsg chalk.green('info'), msg

exports.warn = (msg) ->
  logMsg chalk.black.bgYellow('warn'), msg

exports.error = (msg) ->
  logMsg chalk.black.bgRed('err!'), msg

exports.debug = (msg) ->
  logMsg chalk.gray('dbg?'), msg
