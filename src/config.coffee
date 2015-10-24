nconf = require 'nconf'
tilde = require 'expand-tilde'
cson = require 'cson'
chalk = require 'chalk'

defaults =
  logger:
    level: 'info'
  git:
    auth: {}
  cache:
    size: 0
    root: "~/.gitwalk"
  #resolvers: these two sections may be filled from the respective modules
  #processors:

csonFormat =
  stringify: (obj, opts) ->
    result = cson.strinify obj, opts
    if result instanceof Error
      console.error chalk.bgRed.black("Configuration error: #{result.message}")
      return ""
    else
      return result

  parse: (src, opts) ->
    result = cson.parse src, opts
    if result instanceof Error
      console.error chalk.bgRed.black("Configuration error: #{result.message}")
      return {}
    else
      return result

nconf.env '__'
     .file 'user-cson', file: (tilde '~/.gitwalk.cson'), format: csonFormat
     .file 'user', file: tilde '~/.gitwalk.json'
     .file 'system-cson', file: '/etc/gitwalk.cson', format: csonFormat
     .file 'system', file: '/etc/gitwalk.json'
     .defaults defaults
module.exports = nconf
