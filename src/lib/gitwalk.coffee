# The main of this module

engine = require './engine'
proc = require './processors'

# Perform actions on groups of repositories.
#
# @param [String] expression  The expression that selects which repositories
#                             will be processed. It consists of the repository
#                             selector and object selector within the repo.
# @param [function] processor The function that will be called for every object
#                             according to the expression. The signature of the
#                             callback can vary, please refer to the docs for
#                             the expression you're using.
# @param [function] callback  Called after all repositories and objects have
#                             been processed with no arguments or earlier if an
#                             error occurs with the error as the first argument.
module.exports = gitwalk = (expression, processor, callback) ->
  eng = new engine.Engine(expression, processor)
  eng.run callback

module.exports.proc = new -> @[name] = mod.generator for name, mod of proc; @
