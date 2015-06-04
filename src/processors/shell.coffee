# iterates through files in the repository

child_process = require 'child_process'
utils = require '../utils'


# Run a shell command with the repository as cwd. The command will be run
# using the `child_process.exec` function.
#
# @param repo [nodegit.Repository] The object representing the repo.
# @param finished [function (err)] A callback to report that the command has
#                                  finished
# @param command [String] The command to execute.
#
module.exports = shell = (repo, finished, command) ->
  repoLoc = repo.path()
  command = expandVars command, {repo: repoLoc}

  child_process.exec command, {cwd: repoLoc}, (err, stdout, stderr) ->
    console.log stdout
    console.log stderr

    finished err
