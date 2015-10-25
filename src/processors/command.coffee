# iterates through files in the repository

child_process = require 'child_process'
utils = require '../utils'
logger = require '../logger'

# Returns a shell processor initialised with `command`
#
# @param command [String] The command to execute.
#
module.exports = command = (command) ->
  return (repo, callback) ->
    repoLoc = repo.workdir()
    command = utils.expandVars command, {repo: repoLoc}

    ###
    child_process.exec command, {cwd: repoLoc}, (err, stdout, stderr) ->
      stdout_trimmed = stdout.trim()
      stderr_trimmed = stderr.trim()
      console.log stdout_trimmed if stdout_trimmed.length > 0
      console.log stderr_trimmed if stderr_trimmed.length > 0
    ###

    logger.debug "Running '#{command}'"
    proc = child_process.spawn '/bin/sh', ['-c', command],
      stdio: 'inherit'
      cwd: repoLoc

    proc.on 'error', callback
    proc.on 'close', (code) ->
      if code > 0
        logger.error "Command exited with non-zero: #{code}"

      callback()

module.exports.shell = (args) ->
  return shell args.join ' '
