# Iterates through the commit history

async = require 'async'
nodegit = require 'nodegit'
Promise = require 'bluebird'

logger = require '../logger'
utils = require '../utils'

# The callback is called for every commit in the history of the branch
#     (commit, done) ->
module.exports.generator = commits = (callback) ->
  return (repo, finished) ->
    repo.getCurrentBranch()
      .then (ref) ->
        return repo.getBranchCommit ref.shorthand()
      .then (commit) ->
        hist = commit.history()
        p = new Promise (resolve, reject) ->
          hist.on "end", resolve
          hist.on "error", reject
        hist.start()
        return p
      .then (commits) ->
        p = new Promise (resolve, reject) ->
          async.eachSeries commits, ((commit, done) ->
            logger.debug "On commit #{logger.highlight commit.sha().substr(0,7)}"
            callback(commit, done)
          ),
          ((err) ->
            return reject err if err?
            resolve()
          )
        return p
      .catch (err) ->
        finished "Processing commits failed: #{err}"
      .done ->
        finished()

# TODO: Needs fixing
module.exports.shell = (args) ->
  if args.length < 1
    throw new Error "Missing arguments to files: <command>"
    return

  return (repo, finished) ->
    argsCopy = args.slice()

    func = commits (commit, callback) ->
      vars =
        sha: commit.sha()
        message: commit.message()
        summary: commit.summary()
        author: commit.author()
        committer: commit.committer()

      command = utils.expandVars argsCopy.join(' '), vars
      utils.runCommand command, repo.workdir(), callback

    func repo, finished
