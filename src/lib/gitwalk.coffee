# The main of this module

engine = require './engine'
proc = require './processors'
logger = require './logger'
git = require './git'

# Processing groups of git repositories.
#
# @param [String/Array] expr  The expressions that select which repositories
#                             will be processed. It consists of the repository
#                             selector and object selector within the repo.
# @param [function] proc      The function that will be called for every object
#                             according to the expression. The signature of the
#                             callback can vary, please refer to the docs for
#                             the expression you're using.
# @param [function] callback  Called after all repositories and objects have
#                             been processed with no arguments or earlier if an
#                             error occurs with the error as the first argument.
module.exports = gitwalk = (expr, proc, callback) ->
  try
    eng = new engine.Engine(expr, proc)
    eng.run callback
  catch err
    logger.debug err.stack
    logger.error err
    callback()

module.exports.proc = new -> @[name] = mod.generator for name, mod of proc; @
module.exports.authCallbacks = git.getCallbacks
