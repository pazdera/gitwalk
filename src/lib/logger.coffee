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

exports.set = (opts) ->
  if opts.colours?
    switch opts.colours
      when 'always' then chalk.enabled = true
      when 'off' then chalk.enabled = false
      when 'auto' then chalk.enabled = chalk.supportsColor
      else
        warn "Colour setting #{highlight opts.colours} not recognised"

  if opts.level?
    logLevel = LEVELS[opts.level]

exports.highlight = highlight = (string) ->
  chalk.yellow string

exports.info = (msg) ->
  logMsg LEVELS.info, chalk.green('info'), msg

exports.warn = (msg) ->
  logMsg LEVELS.warn, chalk.black.bgYellow('warn'), msg

exports.error = (msg) ->
  logMsg LEVELS.error, chalk.black.bgRed('err!'), msg

exports.debug = (msg) ->
  logMsg LEVELS.debug, chalk.bgBlack('dbg?'), msg
