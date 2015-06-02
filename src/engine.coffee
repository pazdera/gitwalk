# Resolver of the repository selectors

fs = require 'fs'
path = require 'path'
nodegit = require 'nodegit'
async = require 'async'

logger = require './logger'
getBackend = require './backend'
proc = require './proc'
cache = require './cache'
git = require './git'
utils = require './utils'

# Thrown by the engine when a clone fails
#
# This exception is caught and the engine retries with
# an alternative URL if available.
#
class CloneError extends Error

class exports.Engine
  constructor: (@expression) ->
    @backend = getBackend @expression

  run: (callback) ->
    @backend.resolve (err, queries) =>
      throw err if err?

      for query in queries
        do (query) =>
          git.prepareRepo query.name, query.urls, (err, repo) =>
            throw err if err?
            git.getUpToDateRefs repo, (err, reflist) =>
              throw err if err?
              [head, remoteRefs] = @filterRefs reflist, query
              git.forceUpdateLocalBranches repo, head, remoteRefs, (err, branches) =>
                throw err if err?
                @checkoutBranches branches, repo, query, callback

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

  checkoutBranches: (branches, repo, query, callback) =>
    logger.info 'Starting to process repositories'
    async.eachSeries branches, ((branchRef, done) =>
      console.log "Checking out #{branchRef.shorthand()}"
      nodegit.Checkout.tree repo, branchRef.name(), checkoutStrategy: nodegit.Checkout.STRATEGY.FORCE
        .then =>
          console.log "checkout complete"
          @callProcessor repo, query, done, callback
          console.log "after resolve"
        .catch (err) =>
          console.log "qq",err
          throw err
    ),
    ((err) =>
      throw err if err?
    )

  callProcessor: (repo, query, finished, callback) ->
    processor = proc.getProcessor query
    if processor
      args = query.proc.args.slice()
      args.unshift finished
      args.unshift repo
      args.push callback

      processor.apply @, args
    else
      callback repo, finished
