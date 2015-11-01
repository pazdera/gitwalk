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
  label = "#{label} " if label.length > 0
  if not logLevel or logLevel >= level
    console.log "#{chalk.blue 'gitwalk'} #{label}#{msg}"

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

exports.info = info = (msg, tag=null) ->
  if tag?
    tag = "#{tag}    ".substr(0, 4) if tag.length < 4
    tag = chalk.cyan tag
  else
    tag = chalk.green 'info'

  logMsg LEVELS.info, tag, msg

exports.warn = warn = (msg, tag=null) ->
  tag ?= 'warn'
  logMsg LEVELS.warn, chalk.black.bgYellow(tag), msg

exports.error = error = (msg, tag=null) ->
  tag ?= 'err!'
  logMsg LEVELS.error, chalk.black.bgRed(tag), msg

exports.debug = debug = (msg, tag=null) ->
  tag ?= 'dbg?'
  logMsg LEVELS.debug, chalk.bgBlack(tag), msg
