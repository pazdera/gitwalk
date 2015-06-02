# Convenience functions built on top of nodegit

nodegit = require 'nodegit'
path = require 'path'

cache = require './cache'
utils = require './utils'


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
      return (nodegit.Cred.sshKeyNew userName, '/Users/radek/.ssh/id_rsa.pub', '/Users/radek/.ssh/id_rsa', '')


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

  for ref in remoteRefs
    abort = do (ref) ->
      console.log "processing #{ref.shorthand()}"
      localBranch = path.basename ref.shorthand()

      # detach head if it would be overriden
      if head and localBranch == head.shorthand()
        rv = repo.detachHead defSig, "Temporarily detaching head"
        if rv
          callback "Unable to detach HEAD"
          return true

      repo.getBranchCommit ref
        .then (commit) ->
          return nodegit.Branch.create repo, localBranch, commit, 1, defSig, "#{localBranch}: created by gitwalk"
        .then (branch) ->
          console.log "Created #{branch.shorthand()} (upstream #{ref})"
          console.log nodegit.Branch.setUpstream branch, ref.shorthand()
          branches.push branch

          if head and localBranch == head.shorthand()
            return repo.setHead branch.name(), defSig, "Reattaching head."
          else
            return 0
        .then (result) ->
          if result
            callback "Unable to attach head"
            return true

          count--
          if count <= 0
            callback null, branches
        .catch (err) ->
          callback err
          return true
        .done (rv) ->
          console.log "rv:" + rv
          console.log 'processBranches done!'
          return rv

    return if abort

module.exports =
  nodegit_opts: opts
  getUpToDateRefs: getUpToDateRefs
  prepareRepo: prepareRepo
  forceUpdateLocalBranches: forceUpdateLocalBranches
