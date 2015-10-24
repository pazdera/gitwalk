# iterates through files in the repository

recursive = require 'recursive-readdir'
async = require 'async'

logger = require '../logger'

module.exports = files = (pathRe, callback) ->
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
