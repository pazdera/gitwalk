# Resolver of the repository selectors

path = require 'path'
crypto = require 'crypto'
tilde = require 'tilde-expansion'
getBackend = require './backend'

cb = (repo_handle) ->
  # Read files in the repository
  # Filter and
  # Call a callback

class exports.Engine
  constructor: (@expression) ->
    @backend = getBackend @expression

  run: (callback) ->
    @backend.resolve (queries) =>
      for query in queries
        @get_cache_dir
      repo_url = 'https://github.com/pazdera/tco.git'
      cache_dir_name = path.basename repo_url, '.git'

      opts =
        remoteCallbacks:
          # GitHub will fail cert check on some OSX machine.
          # This overrides that check.
          certificateCheck: () ->
            return 1

      nodegit.Clone repo_url, cache_dir_path, opts
        .then (repo_handle) ->
          callback repo_handle
        .catch (error) ->
          console.log error

  # TODO Move this to a separate Cache class
  getCacheDir: (repoName, repoUrl, callback)
    tilde '~/.gitwalk', (cache_root) ->
      # Make the name unique by appending the hash of the URL at the end
      sha = crypto.createhash 'sha1'
      sha.update repo_url
      cache_dir_name = "#{repo_name}-#{sha.digest 'hex'}"

      cache_dir_path = path.normalize path.join cache_root, cache_dir_name

      callback cache_dir_name
