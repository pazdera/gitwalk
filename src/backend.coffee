# Choose the appropriate backend resolver for the engine

github = require './resolvers/github'

module.exports = getBackend = (expression) ->
  if github.test expression
    return new github.GitHub expression
