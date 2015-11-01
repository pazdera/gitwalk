# Resolver of the repository selectors

fs = require 'fs'
path = require 'path'
nodegit = require 'nodegit'
async = require 'async'
spinner = require 'char-spinner'

logger = require './logger'
cache = require './cache'
git = require './git'
utils = require './utils'
getResolver = require './resolvers'
ExpressionSet = require('./expressions').ExpressionSet

class exports.Engine
  constructor: (expressions, @processor) ->
    if !(expressions instanceof Array)
      expressions = [expressions]
    @expressions = new ExpressionSet expressions, getResolver

  run: (callback) ->
    msg = 'Evaluating expression'
    msg += 's' if @expressions.length > 1
    logger.info msg
    interval = spinner()

    @expressions.getQueries (err, queries) =>
      return callback err if err?

      if queries.length == 0
        logger.warn 'No matches found.'
        return callback null

      clearInterval interval
      # Dry run
      unless @processor?
        logger.info "Matched #{queries.length} repositories:"
        for query in queries
          logger.info "  #{logger.highlight query.name}: #{query.urls[0]}"
        callback null
      else
        @do_run queries, callback

  do_run: (queries, callback) ->
    cache.initCache (err) =>
      return callback err if err?

      logger.debug 'Starting to process repositories'
      async.eachSeries queries, ((query, done) =>
        logger.info "Repository #{logger.highlight query.name}"
        git.prepareRepo query.name, query.urls, (err, repo) =>
          return done err if err?
          @updateRepo repo, query, (err, branches) =>
            return done err if err?
            if branches.length == 0
              logger.warn 'No matching branches found.'
              return done null
            @processBranches branches, repo, query, done
      ), callback

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

    return [head, remoteRefs]

  processBranches: (branches, repo, query, callback) =>
    async.eachSeries branches, ((branchRef, done) =>
      git.forceCheckoutBranch repo, branchRef, (err) =>
        return done err if err?
        try
          logger.debug 'Starting processing'
          @processor repo, done
        catch err
          done err
    ),
    ((err) ->
      callback err
    )
