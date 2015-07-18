# Resolve online and remote paths
# This resolver acts as a fallback
#
# gitwalk ../abc.git ../woot.git@master:/plain.bit
# gitwalk http://github.com/pazdera@master/woot.js
# gitwalk ../gitwalk@*$ woot

async = require 'async'
glob = require 'glob'
minimatch = require 'minimatch'
tilde = require 'expand-tilde'
path = require 'path'

utils = require '../utils'

class exports.Basic
  constructor: (expression) ->
    parts = expression.split '@'

    secondPart = parts.pop()
    firstPart = parts.join '@'

    match = secondPart.match /([^\/\$]+)((\/.*)|\$)$/
    if !match
      throw 'Incorrect expression'

    @pathPattern = firstPart + '/.git/'
    @branch = match[1]
    @proc = match[2]

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
          branchRe: minimatch.makeRe @branch

        if @proc
          query.proc = utils.matchProc @proc
          unless query.proc?
            done "Unknown processor syntax (#{@proc})"
            return

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


# Quickly check whether a string could be a basic expression
#
# @param [String] expression The expression to test.
#
# @return [Boolean] True when the expression matches.
#
exports.test = (expression) ->
  return true #/^(\.|\/)/.test expression
