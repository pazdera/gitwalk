# Resolver of the repository selectors

# library interface:
#   gitwalk 'exp/.*', (file, done) ->
#
#   gitwalk 'exp$', "ls -l"
#
#   gitwalk 'exp#', (commit, author, message, done) ->
#
#   gitwalk 'exp', (repo, done) ->
#
#   gitwalk.configure (conf) ->
#     conf.async = false
#     conf.regex = false
#

# terminal ui:
#   gitwalk 'exp/dir/.*', 'grep 'class List' #{file}'
#
#   gitwalk 'exp$', 'ls -l'
#
#   gitwalk 'exp#', 'echo #{commit} [#{author}] #{message}'
#
#   gitwalk 'exp', './do-something #{repo}'
#
#   gitwalk -r -a
#
#   gitwalk -V -h
#

fs = require 'fs'
path = require 'path'
nodegit = require 'nodegit'
async = require 'async'

logger = require './logger'
getResolver = require './resolvers'
getProcessor = require './processors'
cache = require './cache'
git = require './git'
utils = require './utils'


class exports.Engine
  constructor: (@expression, iterArgs...) ->
    @backend = getResolver @expression
    @iterArgs = iterArgs

  # TODO: Change throws for callbacks
  run: (callback) ->
    @backend.resolve (err, queries) =>
      return callback err if err?

      if queries.length == 0
        logger.warn 'No matches found.'
        return callback null

      cache.initCache (err) =>
        return callback err if err?

        logger.info 'Starting to process repositories'
        async.eachSeries queries,
          ((query, done) =>
            logger.info "Processing #{query.name}"
            git.prepareRepo query.name, query.urls, (err, repo) =>
              return done err if err?
              @updateRepo repo, query, (err, branches) =>
                return done err if err?
                if branches.length == 0
                  logger.warn 'No matching branches found.'
                  return done null
                @processBranches branches, repo, query, @iterArgs, done
          ),
          ((err) ->
            callback err
          )

  updateRepo: (repo, query, callback) ->
    git.getUpToDateRefs repo, (err, reflist) =>
      if err?
        callback err
      else
        [head, remoteRefs] = @filterRefs reflist, query
        return callback null, [] if remoteRefs.length == 0
        git.forceUpdateLocalBranches repo, head, remoteRefs, (err, branches) ->
            callback err, branches

  filterRefs: (reflist, query) ->
    remoteRefs = []
    head = null

    for ref in reflist
      do ->
        head = ref if ref.isHead()

        if ref.isConcrete() and ref.isRemote()
          localName = path.basename ref.shorthand()
          if query.branchRe.test localName
            remoteRefs.push ref

    console.log 'Matching remotes:'
    for b in remoteRefs
      console.log b.name()

    return [head, remoteRefs]

  processBranches: (branches, repo, query, iterArgs, callback) =>
    async.eachSeries branches, ((branchRef, done) =>
      git.forceCheckoutBranch repo, branchRef, (err) =>
        return done err if err?
        @callProcessor repo, query, iterArgs, done
    ),
    ((err) ->
      callback err
    )

  # TODO: all expressions must have matching processors
  callProcessor: (repo, query, iterArgs, finished) ->
    processor = getProcessor query
    console.log query
    if processor
      args = query.proc.args.slice()
      args.unshift finished
      args.unshift repo
      Array::push.apply args, iterArgs
      console.log args

      processor.apply @, args
    else
      callback repo, finished
