# Choose the appropriate backend resolver for the engine

github = require './github'
url = require './url'
glob = require './glob'

module.exports = getResolver = (expression) ->
  if github.test expression
    return new github.GitHub expression
  else if url.test expression
    return new url.Url expression
  else
    return new glob.Glob expression
