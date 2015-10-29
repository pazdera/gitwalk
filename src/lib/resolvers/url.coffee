# Resolve remote URLs

async = require 'async'
glob = require 'glob'
tilde = require 'expand-tilde'
path = require 'path'

utils = require '../utils'
logger = require '../logger'

class exports.Url
  constructor: (expression) ->
    parts = expression.split ':'

    if parts.length < 3
      secondPart = null
      firstPart = expression
    else
      secondPart = parts.pop()
      firstPart = parts.join ':'

    @url = firstPart
    @branch = if secondPart then new RegExp secondPart else /master/

    logger.debug "URL: #{@url}, branch #{@branch.source}"

  resolve: (callback) ->
    return callback null, [
        name: path.basename @url
        urls: [@url]
        branchRe: @branch
      ]

removeGitDirFromPath = (gitDirPath) ->
  pathParts = gitDirPath.split '/'
  pathParts.pop()
  pathParts.pop()
  return pathParts.join '/'


# Quickly check whether a string could be a basic expression
#
# @param [String] expression The expression to test.
#
# @return [Boolean] True when the expression matches.
#
exports.test = (expression) ->
  return /^.+\:\/\//.test expression
