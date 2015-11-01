# Convenience functions built on top of nodegit

nodegit = require 'nodegit'
path = require 'path'
async = require 'async'
minimatch = require 'minimatch'
spinner = require 'char-spinner'

config = require './config'
cache = require './cache'
utils = require './utils'
logger = require './logger'

getOpts = ->
  fetchOpts:
    callbacks:
      # GitHub will fail cert check on some OSX machines.
      # This overrides that check.
      #
      # TODO: Maybe this could check whether what platform are we on?
      certificateCheck: ->
        return 1

      credentials: (url, userName) ->
        creds = config.get 'git:auth'
        for id, cred of creds
          re = new RegExp cred['pattern']
          if url.match re
            switch
              when 'username' of cred and 'password' of cred
                logger.debug "Using plain auth (#{id})"
                return nodegit.Cred.userpassPlaintextNew cred.username,
                                                         cred.password
              when 'public_key' of cred and 'private_key' of cred and \
                   'passphrase' of cred
                logger.debug "Using SSH (#{id})"
                return nodegit.Cred.sshKeyNew userName,
                                              cred.public_key,
                                              cred.private_key,
                                              cred.passphrase
              else
                logger.warn "Misconfigured git auth for #{id}"

        logger.debug "No auth method found for this URL"
        return nodegit.Cred.defaultNew()


# Thrown by the engine when a clone fails
#
# This exception is caught and the engine retries with
# an alternative URL if available.
#
class CloneError extends Error then constructor: -> super


cloneRepo = (repoUrl, targetDir, callback) ->
  logger.info "Cloning from #{repoUrl}"
  interval = spinner()
  opts = getOpts()
  nodegit.Clone.clone repoUrl, targetDir, opts
    .then (repo) ->
      logger.debug 'Cloned successfully'
      clearInterval interval
      callback null, repo
    .catch (err) ->
      logger.error "Operation failed (#{err})"
      logger.debug err.stack
      callback new CloneError "Failed to clone the repository"
    .done ->


openRepo = (repoUrl, targetDir, callback) ->
  logger.debug "Opening repo at #{targetDir}"
  nodegit.Repository.open targetDir
    .then (repo) ->
      callback null, repo
    .catch (err) ->
      logger.error err.message
      logger.debug err.stack
      logger.error "Please run `rm -rf #{targetDir}` to remove this "+
                   "repository from cache and try again"
      callback new Error "Failed to open the cached repository"
    .done ->


getRepoHandle = (repoUrl, dir, callback) ->
  utils.fileExists dir, (itDoes) ->
    if itDoes
      openRepo repoUrl, dir, callback
    else
      cloneRepo repoUrl, dir, callback


# Fetch and return a list of all references in the repo
getUpToDateRefs = (repo, callback) ->
  logger.debug "Fetching updates"
  interval = spinner()
  repo.fetchAll getOpts().fetchOpts
    .then ->
      clearInterval interval
      logger.debug "Fetched successfully"
      return repo.getReferences(nodegit.Reference.TYPE.LISTALL)
    .then (reflist) ->
      callback null, reflist
    .catch (err) ->
      logger.error err.message
      logger.debug err.stack
      callback new Error 'Failed to fetch updates from remote'
    .done ->


prepareRepo = (name, cloneUrls, callback) ->
  url = cloneUrls.shift()
  cache.getCacheDir name, url, (cacheDir) ->
    getRepoHandle url, cacheDir, (err, repo) ->
      if err?
        if err instanceof CloneError
          if cloneUrls.length == 0
            callback new Error "Unable to clone the repository"
          else
            # Try again with an alternative URL
            prepareRepo name, cloneUrls, callback
        else
          logger.error "An error occured while accessing #{name} (#{err.message})"
          callback err
      else
        callback null, repo


forceUpdateLocalBranches = (repo, head, remoteRefs, callback) ->
  branches = []
  count = remoteRefs.length

  #defSig = nodegit.Signature.default repo

  async.eachSeries remoteRefs,
    ((ref, done) ->
      logger.debug "Updating HEAD of #{path.basename ref.shorthand()}"
      localBranch = path.basename ref.shorthand()

      # detach head if it would be overriden
      if head and localBranch == head.shorthand()
        rv = repo.detachHead()
        if rv
          return done "Unable to detach HEAD"

      repo.getBranchCommit ref
        .then (commit) ->
          return nodegit.Branch.create repo, localBranch, commit, 1
        .then (branch) ->
          nodegit.Branch.setUpstream branch, ref.shorthand()
          branches.push branch

          if head and localBranch == head.shorthand()
            return repo.setHead branch.name()
          else
            return 0
        .then (rv) ->
          if rv
            throw "Unable to attach head"
          else
            done()
        .catch (err) ->
          done err
        .done ->
    ),
    ((err) ->
      callback err, branches
    )


forceCheckoutBranch = (repo, branchRef, callback) ->
  logger.info "On branch #{logger.highlight branchRef.shorthand()}"
  repo.checkoutBranch branchRef.name(),
                      checkoutStrategy: nodegit.Checkout.STRATEGY.FORCE
    .then ->
      logger.debug 'Checked out successfully'
      callback null
    .catch (err) ->
      callback err
    .done ->

module.exports =
  getUpToDateRefs: getUpToDateRefs
  prepareRepo: prepareRepo
  forceUpdateLocalBranches: forceUpdateLocalBranches
  forceCheckoutBranch: forceCheckoutBranch
