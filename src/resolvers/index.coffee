# Choose the appropriate backend resolver for the engine

github = require './github'
basic = require './basic'

module.exports = getResolver = (expression) ->
  if github.test expression
    return new github.GitHub expression
  else
    return new basic.Basic expression
