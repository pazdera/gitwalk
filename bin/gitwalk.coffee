# the main for gitwalk CLI

# example commands
#   gitwalk 'github:pazdera/.*@master/.*\.js' 'grep TODO #{file}'
#   gitwalk 'github:pazdera/.*@master'    'tree #{repo}'
#   gitwalk 'github:pazdera/.*@master?'

program = require 'commander'
pkginfo = require '../package.json'
gitwalk = require '../src/gitwalk'
processors = require '../src/processors'
logger = require '../src/logger'

program
  .version pkginfo.version
  .usage '[options] <expr...> <proc> <cmd...>'
  .option '-a, --async', 'Process the repositories asynchronously in parallel'
  .option '-r, --regex', 'Use regular expressions instead of minimax matching'
  .parse process.argv

expressions = []
proc = null
procName = null
procArgs = []

while program.args.length > 0
  arg = program.args.shift()
  if arg of processors
    proc = processors[arg]
    procName = arg
    procArgs = program.args
    break
  else
    expressions.push arg

if !('shell' of proc)
  logger.error "#{procName} isn't supported on the command-line yet"
  process.exit 1

gitwalk expressions, proc.shell(procArgs), (err) ->
  if err?
    console.log err.stack
    logger.error err
    process.exit 1
  else
    process.exit()
