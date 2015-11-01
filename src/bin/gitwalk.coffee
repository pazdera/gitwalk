# the main for gitwalk CLI

# example commands
#   gitwalk 'github:pazdera/.*@master/.*\.js' 'grep TODO #{file}'
#   gitwalk 'github:pazdera/.*@master'    'tree #{repo}'
#   gitwalk 'github:pazdera/.*@master?'

program = require 'commander'
pkginfo = require '../../package.json'
gitwalk = require '../lib/gitwalk'
processors = require '../lib/processors'
logger = require '../lib/logger'
cache = require '../lib/cache'

program
  .version pkginfo.version
  .usage '[options] <expr...> <proc> <cmd...>'
  .option '-w, --wipe-cache', 'Clear the cache and exit'
  .option '-c, --colours <setting>', 'Either \'always\', \'off or \'auto\' (default)'
  .option '-v, --verbose', 'Show debugging prints'
  .option '-d, --dry-run', 'Only print the list of matching repos'
  .parse process.argv

expressions = []
proc = null
procName = null
procArgs = []

logger.set
  colours: program.colours
  level: if program.verbose then 'debug' else null

switch
  when program.wipeCache
    cache.clearCache (err) ->
      rv = 0
      if err?
        logger.error err
        rv = 1

      process.exit rv
  when program.args.length is 0
    program.outputHelp()
    process.exit 1
  else
    while program.args.length > 0
      arg = program.args.shift()
      if arg of processors
        proc = processors[arg]
        procName = arg
        procArgs = program.args
        break
      else
        expressions.push arg

    if program.dryRun
      gitwalk expressions, null, (err) ->
        if err?
          logger.error err
          process.exit 1
        else
          process.exit()
    else
      unless proc?
        logger.error 'Missing processor'
        program.outputHelp()
        process.exit 1

      if !('shell' of proc)
        logger.error "#{procName} isn't supported on the command-line yet"
        process.exit 1

      gitwalk expressions, proc.shell(procArgs), (err) ->
        if err?
          logger.error err
          process.exit 1
        else
          process.exit()
