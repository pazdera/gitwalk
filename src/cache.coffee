# Managing the repository cache

path = require 'path'
crypto = require 'crypto'
tilde = require 'tilde-expansion'

CACHE_ROOT = '~/.gitwalk'


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
  tilde CACHE_ROOT, (cacheRoot) ->
    # Make the name unique by appending the hash of the URL at the end
    dirName = "#{repoName}-#{getSHA1 repoUrl}"

    cacheDirPath = path.normalize path.join cacheRoot, dirName
    callback cacheDirPath


module.exports =
  getCacheDir: getCacheDir
