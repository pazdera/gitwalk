nconf = require 'nconf'
tilde = require 'expand-tilde'

defaults =
  logger:
    level: 'info'
  cache:
    root: '~/.gitwalk'
  git:
    key:
      public: null
      private: null
  cache:
    size: 0
    root: "~/.gitwalk"
  #selectors: these two sections may be filled from the respective modules
  #iterators:

nconf.env('__')
     .file('user', file: tilde '~/.gitwalk.json')
     .file('system', file: '/etc/gitwalk.json')
     .defaults defaults
module.exports = nconf
