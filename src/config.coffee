nconf = require 'nconf'
tilde = require 'expand-tilde'

defaults =
  logger:
    level: 'info'
  cache:
    root: '~/.gitwalk'
  #selectors:
  #iterators:

nconf.env('__')
     .file('user', file: tilde '~/.gitwalk.json')
     .file('system', file: '/etc/gitwalk.json')
     .defaults defaults
module.exports = nconf
