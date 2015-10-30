# Resolve remote URLs

async = require 'async'
glob = require 'glob'
tilde = require 'expand-tilde'
path = require 'path'
fs = require 'fs'

utils = require '../utils'
config = require '../config'
logger = require '../logger'
ExpressionSet = require('../expressions').ExpressionSet

class exports.Group
  constructor: (expression, @getResolver) ->
    @name = @parseExpression expression

    logger.debug "Group: #{@name}"

  parseExpression: (expression) ->
    match = expression.match /^group\:(.+)/

    unless match
      throw new Error 'This isn\'t a valid group expression'

    match[1]

  # Returs a list of queries for the engine
  resolve: (callback) ->
    expressions = config.get "resolvers:groups:#{@name}"
    unless utils.isArray expressions
      throw new Error "Group '#{@name}' must be an array of expressions"

    expSet = new ExpressionSet expressions, @getResolver
    expSet.getQueries callback

# Quickly check whether a string could be a basic expression
#
# @param [String] expression The expression to test.
#
# @return [Boolean] True when the expression matches.
#
exports.test = (expression) ->
  /^group\:/.test expression
