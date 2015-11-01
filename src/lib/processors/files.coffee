# iterates through files in the repository

glob = require 'glob'
async = require 'async'
path = require 'path'

logger = require '../logger'
utils = require '../utils'

# The callback is called for every file with the following signature
#     (filePath, callback) ->
module.exports.generator = files = (pathPattern, callback) ->
  return (repo, finished) ->
    repoLoc = repo.workdir()
    opts = {ignore: ".git/**/*", cwd: repoLoc, matchBase: true, nodir: true}
    glob pathPattern, opts, (err, files) ->
      async.eachSeries files, ((filePath, done) ->
        logger.debug "On file #{logger.highlight filePath}"
        callback path.join(repoLoc, filePath), done
      ),
      ((err) ->
        finished err
      )


module.exports.shell = (args) ->
  if args.length <= 1
    throw new Error "Missing arguments to files: <pattern> <command>"
    return

  return (repo, finished) ->
    argsCopy = args.slice()
    pattern = argsCopy.shift()

    func = files pattern, (filePath, callback) ->
      command = utils.expandVars argsCopy.join(' '), file: filePath
      utils.runCommand command, repo.workdir(), callback

    func repo, finished
