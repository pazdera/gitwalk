# Managing the repository cache

path = require 'path'
crypto = require 'crypto'
tilde = require 'expand-tilde'
du = require 'du'
fileSizeParser = require 'filesize-parser'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
filesize = require 'filesize'

config = require './config'
log = require './logger'

# Compute the SHA1 hash of a string
#
# @param inputString [String] The input of the hash function.
#
# @return [String] The hex digest of the hash.
#
getSHA1 = (inputString) ->
  sha = crypto.createHash 'sha1'
  sha.update inputString
  return sha.digest 'hex'


# Generates a path in the cache based on the repo name and URL.
#
# @param repoName [String] The name of the repository.
# @param repoUrl [String] The origin URL (where it will be cloned from).
# @param callback [(String)] A function to pass the result to.
#
getCacheDir = (repoName, repoUrl, callback) ->
  cacheRoot = tilde config.get 'cache:root'

  # Make the name unique by appending the hash of the URL at the end
  dirName = "#{repoName}-#{getSHA1 repoUrl}"

  du cacheRoot, (err, size) ->
  cacheDirPath = path.normalize path.join cacheRoot, dirName
  callback cacheDirPath


# Makes sure that the cache directory exists and that it's not over the
# configured limit.
#
# @param callback [(err)]A function to receive the error (if any).
initCache = (callback) ->
  cacheRoot = tilde config.get 'cache:root'

  maxSize = config.get 'cache:limit'
  maxSize = 0 unless maxSize?
  maxSize = fileSizeParser maxSize if typeof maxSize == 'string'
  if typeof maxSize != 'number'
    return callback "Incorrect cache limit (#{maxSize})"
  if maxSize == 0
    log.debug "Cache limit not set, skipping size check"
    return callback null

  mkdirp cacheRoot, (err) ->
    return callback err if err?

    du cacheRoot, (err, size) ->
      if err?
        log.error err
        return callback 'Unable to get the size of the cache dir'


        if size >= maxSize
          humanReadable = filesize size,
            round: 0
            spacer: ''

          log.debug "Cache over limit: #{humanReadable}"

          # TODO: This could only reduce the size of the cache to half using
          #       some sort of LRU algorithm based on fs timestamps.
          clearCache cacheRoot, callback
        else
          log.debug "Cache size"


# Removes the whole cache directory and recreates it from scratch.
#
# @param cacheRoot [String] The path to the cache.
# @param callback [(err)] A function to receive the error (if any).
#
clearCache = (cacheRoot, callback) ->
  log.debug 'Clearing cache'
  rimraf cacheRoot, (err) ->
    return callback "Failed to clear the cache (#{err})" if err?

    mkdirp cacheRoot, (err) ->
      err = "Failed to reinitalise the cache after cleaning (#{err})" if err?
      callback err


module.exports =
  getCacheDir: getCacheDir
  initCache: initCache
