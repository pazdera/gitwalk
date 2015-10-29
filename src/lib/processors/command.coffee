# iterates through files in the repository

utils = require '../utils'
logger = require '../logger'

# Returns a shell processor initialised with `command`
#
# @param command [String] The command to execute.
#
module.exports.generator = command = (command) ->
  return (repo, callback) ->
    command = utils.expandVars command, {repo: repo.workdir()}
    utils.runCommand command, repo.workdir(), callback

module.exports.shell = (args) ->
  return command args.join ' '
