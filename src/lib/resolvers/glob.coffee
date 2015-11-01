# Resolve local paths using glob

async = require 'async'
glob = require 'glob'
tilde = require 'expand-tilde'
path = require 'path'
minimatch = require 'minimatch'

utils = require '../utils'
logger = require '../logger'

class exports.Glob
  constructor: (expression) ->
    parts = expression.split ':'

    if parts.length > 1
      secondPart = parts.pop()
      firstPart = parts.join ':'
    else
      firstPart = expression
      secondPart = 'master'

    logger.debug "Glob: #{firstPart}, branch #{secondPart}"

    @pathPattern = firstPart + '/.git/'
    @branch = minimatch.makeRe secondPart

  resolve: (callback) ->
    pattern = tilde @pathPattern
    glob pattern, (err, paths) =>
      if err?
        callback err
        return

      engineQueries = []
      async.each paths, ((repoPath, done) =>
        url = removeGitDirFromPath repoPath
        query =
          name: path.basename url
          urls: [url]
          branchRe: @branch

        engineQueries.push query
        done()
      ),
      ((err) ->
        if err?
          callback err
        else
          callback null, engineQueries

        return
      )


removeGitDirFromPath = (gitDirPath) ->
  pathParts = gitDirPath.split '/'
  pathParts.pop()
  pathParts.pop()
  return pathParts.join '/'
