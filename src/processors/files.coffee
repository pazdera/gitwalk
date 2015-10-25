# iterates through files in the repository

recursive = require 'recursive-readdir'
async = require 'async'

logger = require '../logger'
utils = require '../utils'

# The callback is called for every file with the following signature
#     (filePath, callback) ->
module.exports.generator = files = (pathRe, callback) ->
  return (repo, finished) ->
    repoLoc = repo.workdir()
    recursive repoLoc, ["#{repoLoc}/.git/**"], (err, files) ->
      async.eachSeries files, ((filePath, done) ->
        relativePath = filePath.replace repoLoc, ''

        # Remove the leading '/' if present
        if relativePath.substring(0, 1) == '/'
          relativePath = relativePath.substring 1

        re = new RegExp pathRe
        if re.test relativePath
          logger.info "On file #{logger.highlight relativePath}"
          callback filePath, done
        else
          done()
      ),
      ((err) ->
        finished err
      )


module.exports.shell = (args) ->
  if args.length <= 1
    throw new Error "Missing arguments to files: <pattern> <command>"
    return

  return (repo, finished) ->
    pattern = args.shift()

    func = files pattern, (filePath, callback) ->
      command = utils.expandVars args.join(' '), file: filePath
      utils.runCommand command, repo.workdir(), callback

    func repo, finished
