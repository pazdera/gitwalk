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


class exports.Engine
  constructor: (@expression) ->
    @backend = getBackend @expression

  run: (callback) ->
    @backend.resolve (err, queries) =>
      throw err if err?

      # TODO: This might need an async series loop
      for query in queries
        do (query) =>
          git.prepareRepo query.name, query.urls, (err, repo) =>
            throw err if err?
            @updateRepo repo, query, (err, branches) =>
              throw err if err?
              @processBranches branches, repo, query, callback

  updateRepo: (repo, query, callback) ->
    git.getUpToDateRefs repo, (err, reflist) =>
      if err?
        calback err
      else
        [head, remoteRefs] = @filterRefs reflist, query
        git.forceUpdateLocalBranches repo, head, remoteRefs, (err, branches) =>
          if err?
            callback err
          else
            callback null, branches

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

  processBranches: (branches, repo, query, callback) =>
    logger.info 'Starting to process repositories'
    async.eachSeries branches, ((branchRef, done) =>
      git.forceCheckoutBranch repo, branchRef, (err) =>
        throw err if err?
        @callProcessor repo, query, done, callback
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
