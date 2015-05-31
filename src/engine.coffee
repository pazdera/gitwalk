# Resolver of the repository selectors

fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
tilde = require 'tilde-expansion'
nodegit = require 'nodegit'
async = require 'async'

logger = require './logger'
getBackend = require './backend'

cb = (repo_handle) ->
  # Read files in the repository
  # Filter and
  # Call a callback

class CloneError extends Error

class exports.Engine
  constructor: (@expression) ->
    @backend = getBackend @expression

    @opts =
      remoteCallbacks:
        # GitHub will fail cert check on some OSX machine.
        # This overrides that check.
        certificateCheck: ->
          return 1
        credentials: (url, userName) ->
            console.log userName
            #return nodegit.Cred.sshKeyFromAgent(userName)
            return (nodegit.Cred.sshKeyNew userName, '/Users/radek/.ssh/id_rsa.pub', '/Users/radek/.ssh/id_rsa', '')

  run: (callback) ->
    @backend.resolve (err, queries) =>
      throw err if err

      for query in queries
        console.log query
        url = query.urls.shift()
        @tryUrl url, query.urls, query, callback

  tryUrl: (url, altUrls, query, callback) ->
    console.log url
    @getCacheDir query.name, url, (cacheDir) =>
      console.log cacheDir
      try
        @prepareRepo url, cacheDir, (err, repoHandle) =>
          throw err if err

          console.log 'Got repo handle!'
          repoHandle.fetchAll(@opts.remoteCallbacks)
            .then =>
              console.log "fetch done"
              return repoHandle.getReferences()
            .then (reflist) =>
              @processBranches repoHandle, reflist, query, callback
            .catch (error) =>
              console.log error
              throw error
            .done =>
              console.log 'Done!'
      catch err
        console.log "xx", err
        if err instanceof CloneError
          if altUrls.length > 0
            url = altUrls.shift()
            @tryUrl url, altUrls, query, callback
          else
            calback "Unable to clone the repository #{query.name}", null
            return
        else
          throw err

          # list branches
          # filter based on re
          # clean up current branch: fetch origin, reset --hard
          # for branch in branches
          #   checkout branch
          #   pass repo path to the callback
          #   see whether there is a processor in the expression
          #   wrap in processor
          #   DONE

  processBranches: (repoHandle, reflist, query, callback) ->
    matchingRemotes = []
    head = null

    for ref in reflist
      head = ref if ref.isHead()

      if ref.isConcrete() and ref.isRemote()
        localName = path.basename ref.shorthand()
        if query.branch_re.test localName
          console.log "Pushing to remotes #{ref.name()}"
          matchingRemotes.push ref

    console.log 'Matching remotes:'
    for b in matchingRemotes
      console.log b.name()

    branches = []
    count = matchingRemotes.length
    console.log "count: #{count}"
    if !count
      # no need to create local branches
      callback branches
      return

    # Make sure there are local tracking branches for all remotes
    # and that they're up to date
    console.log matchingRemotes
    for ref in matchingRemotes
      do (ref) =>
        console.log "processing #{ref.shorthand()}"
        localBranchName = path.basename ref.shorthand()

        # detach head if it would be overriden
        if head and localBranchName == head.shorthand()
          rv = repoHandle.detachHead nodegit.Signature.default(repoHandle),
                                     "Temporarily detaching head"
          throw new Error "Unable to detach HEAD!" if rv

        repoHandle.getBranchCommit ref
          .then (commit) =>
            return nodegit.Branch.create repoHandle, localBranchName, commit, 1, nodegit.Signature.default(repoHandle), "#{localBranchName}: created by gitwalk"
          .then (branch) =>
            console.log "Created #{branch.shorthand()} (upstream #{ref})"
            console.log nodegit.Branch.setUpstream branch, ref.shorthand()
            branches.push branch

            if head and localBranchName == head.shorthand()
              return repoHandle.setHead branch.name(), nodegit.Signature.default(repoHandle), "Reattaching head."
            else
              return 0
          .then (result) =>
            if result
              throw "Unable to attach head"

            count--
            if count <= 0
              @checkoutBranches branches, repoHandle, callback
          .catch (err) =>
            console.log "yy", err
            throw err
          .done =>
            console.log 'processBranches done!'

  checkoutBranches: (branches, repoHandle, callback) =>
    logger.info 'Starting to process repositories'
    async.eachSeries branches, ((branchRef, done) =>
      console.log "Checking out #{branchRef.shorthand()}"
      nodegit.Checkout.tree repoHandle, branchRef.name(), checkoutStrategy: nodegit.Checkout.STRATEGY.FORCE
        .then =>
          console.log "checkout complete"
          callback repoHandle.path()
          done null
        .catch (err) =>
          console.log "qq",err
          throw err
    ),
    ((err) =>
      if err
        console.log "ww",err
        throw err
    )

  # TODO Move this to a separate Cache class
  getCacheDir: (repoName, repoUrl, callback) ->
    tilde '~/.gitwalk', (cacheRoot) =>
      # Make the name unique by appending the hash of the URL at the end
      sha = crypto.createHash 'sha1'
      sha.update repoUrl
      dirName = "#{repoName}-#{sha.digest 'hex'}"

      dirPath = path.normalize path.join cacheRoot, dirName
      callback dirPath

  prepareRepo: (repoUrl, cacheDir, callback) ->
    # check whether the directory exists
    console.log cacheDir
    fs.stat cacheDir, (err, stat) =>
      console.log err
      console.log stat
      if stat
        @openRepo repoUrl, cacheDir, callback
      else
        @cloneRepo repoUrl, cacheDir, callback

  cloneRepo: (repoUrl, cacheDir, callback) ->
    console.log 'cloning ...'
    nodegit.Clone.clone repoUrl, cacheDir, @opts
      .then (repoHandle) ->
        console.log 'downloaded!'
        callback null, repoHandle
      .catch (error) ->
        callback error, null

  openRepo: (repoUrl, cacheDir, callback) ->
    console.log 'openning ...'
    nodegit.Repository.open cacheDir
      .then (repoHandle) ->
        console.log 'open!'
        callback null, repoHandle
      .catch (error) ->
        callback error, null
