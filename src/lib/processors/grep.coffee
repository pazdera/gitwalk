# iterates through files in the repository

glob = require 'glob'
async = require 'async'
path = require 'path'
fs = require 'fs'
chalk = require 'chalk'

logger = require '../logger'
utils = require '../utils'

# TODO
#
# gitwak 'github:pazdera/wicked', gitwalk.proc.grep 'woot.*', '*.js', (err) ->
# gitwalk 'github:pazdera/wicked' grep 'woot.*' '*.js'
# The callback is called for every file with the following signature
#     (filePath, callback) ->
module.exports.generator = grep = (rePattern, pathPattern='**/*') ->
  return (repo, finished) ->
    repoLoc = repo.workdir()
    opts = {ignore: ".git/**/*", cwd: repoLoc, matchBase: true, nodir: true}
    re = new RegExp rePattern
    glob pathPattern, opts, (err, files) ->
      async.eachSeries files, ((filePath, done) ->
        fs.readFile path.join(repoLoc, filePath), 'utf8', (err, contents) ->
          if err?
            logger.warn "Can't read #{filePath} (#{err})"
          else
            for line, i in contents.split '\n'
              match = line.match re
              if match?
                result = line.replace match[0], chalk.red.bold match[0]
                num = chalk.magenta "#{i+1}"
                logger.info "#{filePath}:#{num}: #{result}", 'grep'
          done()
      ),
      ((err) ->
        finished err
      )

module.exports.shell = (args) ->
  if args.length < 1
    throw new Error "Missing arguments to grep: <pattern> [<file-glob>]"
    return

  if args.length > 2
    throw new Error "Too many to grep: <pattern> [<file-glob>]"
    return

  return grep args[0], args[1]
