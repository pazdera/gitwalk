# Choose the appropriate backend resolver for the engine

github = require './resolvers/github'

exports = getBackend = (expression) ->
  if github.test expression
    return new github.GitHub expression
