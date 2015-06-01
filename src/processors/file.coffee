# iterates through files in the repository

recursive = require 'recursive-readdir'
async = require 'async'

module.exports = file = (repo, finished, pathRe, callback) ->
  repoLoc = repo.path()
  recursive repoLoc, ['#{repoLoc}/.git/**'], (err, files) ->
    async.eachSeries files, ((filePath, done) ->
      relativePath = filePath.replace repoLoc

      # Remove the leading '/' if present
      if relativePath.substring(0, 1) == '/'
        relativePath = relativePath.substring 1

      if pathRe.test relativePath
        callback filePath

      done null
    ),
    ((err) ->
      finished null
      throw err if err
    )
