# Convenience functions built on top of nodegit

nodegit = require 'nodegit'
path = require 'path'
async = require 'async'

config = require './config'
cache = require './cache'
utils = require './utils'
logger = require './logger'

opts =
  remoteCallbacks:
    # GitHub will fail cert check on some OSX machine.
    # This overrides that check.
    certificateCheck: ->
      return 1

    credentials: (url, userName) ->
      # TODO: make this configurable
      #       add plain-text auth
      #return nodegit.Cred.sshKeyFromAgent(userName)
      return nodegit.Cred.sshKeyNew(userName,
                                    config.get('git:key:public'),
                                    config.get('git:key:private'),
                                    '')


# Thrown by the engine when a clone fails
#
# This exception is caught and the engine retries with
# an alternative URL if available.
#
class CloneError extends Error


cloneRepo = (repoUrl, targetDir, callback) ->
  console.log 'cloning ...'
  nodegit.Clone.clone repoUrl, targetDir, opts
    .then (repo) ->
      console.log 'downloaded!'
      callback null, repo
    .catch (err) ->
      callback err
    .done ->


openRepo = (repoUrl, targetDir, callback) ->
  console.log 'openning ...'
  nodegit.Repository.open targetDir
    .then (repo) ->
      console.log 'open!'
      callback null, repo
    .catch (err) ->
      callback err
    .done ->


getRepoHandle = (repoUrl, dir, callback) ->
  utils.fileExists dir, (itDoes) ->
    if itDoes
      openRepo repoUrl, dir, callback
    else
      cloneRepo repoUrl, dir, callback


# Fetch and return a list of all references in the repo
getUpToDateRefs = (repo, callback) ->
  console.log 'Got repo handle!'
  repo.fetchAll opts.remoteCallbacks
    .then ->
      console.log "fetch done"
      return repo.getReferences()
    .then (reflist) ->
      callback null, reflist
    .catch (err) ->
      console.log err
      callback err
    .done ->
      console.log 'Done!'


prepareRepo = (name, cloneUrls, callback) ->
  url = cloneUrls.shift()
  cache.getCacheDir name, url, (cacheDir) ->
    try
      getRepoHandle url, cacheDir, (err, repo) ->
        console.log err, repo
        if err?
          callback err
          return

        callback null, repo
    catch err
      console.log "xx", err
      if err instanceof CloneError
        if cloneUrls.length == 0
          calback "Unable to clone the repository"
        else
          prepareRepo cloneUrls, callback
      else
        throw err

forceUpdateLocalBranches = (repo, head, remoteRefs, callback) ->
  branches = []
  count = remoteRefs.length

  defSig = nodegit.Signature.default repo

  # TODO: This looks like it's broken. The callback will be called twice
  async.eachSeries remoteRefs,
    ((ref, done) ->
      console.log "processing #{ref.shorthand()}"
      localBranch = path.basename ref.shorthand()

      # detach head if it would be overriden
      if head and localBranch == head.shorthand()
        rv = repo.detachHead defSig, "Temporarily detaching head"
        if rv
          return done "Unable to detach HEAD"

      repo.getBranchCommit ref
        .then (commit) ->
          return nodegit.Branch.create repo, localBranch, commit, 1, defSig,
                 "#{localBranch}: created by gitwalk"
        .then (branch) ->
          console.log "Created #{branch.shorthand()} (upstream #{ref})"
          console.log nodegit.Branch.setUpstream branch, ref.shorthand()
          branches.push branch

          if head and localBranch == head.shorthand()
            return repo.setHead branch.name(), defSig, "Reattaching head."
          else
            return 0
        .then (rv) ->
          if rv
            throw "Unable to attach head"
          else
            done()
        .catch (err) ->
          done err
          return true
        .done (rv) ->
          console.log "rv:" + rv
          return rv
    ),
    ((err) ->
      callback err, branches
    )


forceCheckoutBranch = (repo, branchRef, callback) ->
  logger.debug "Checking out #{branchRef.shorthand()}"
  repo.checkoutBranch branchRef.name(),
                      checkoutStrategy: nodegit.Checkout.STRATEGY.FORCE
    .then ->
      callback null
    .catch (err) ->
      callback err
    .done ->

old_forceCheckoutBranch = (repo, branchRef, callback) ->
  defSig = nodegit.Signature.default repo
  console.log "Checking out #{branchRef.shorthand()}"
  nodegit.Checkout.tree repo, branchRef.name(),
                        checkoutStrategy: nodegit.Checkout.STRATEGY.FORCE
    .then ->
      msg = "Checkout: HEAD #{branchRef.name()}"
      console.log branchRef.name()
      return repo.setHead branchRef.name(), defSig, msg
    .then (result) ->
      console.log "checkout complete"
      callback null
      console.log "after resolve"
    .catch (err) ->
      console.log "qq",err
      callback err
    .done ->

module.exports =
  nodegit_opts: opts
  getUpToDateRefs: getUpToDateRefs
  prepareRepo: prepareRepo
  forceUpdateLocalBranches: forceUpdateLocalBranches
  forceCheckoutBranch: forceCheckoutBranch
