# Processor mappings for purposes of matching the ones
# embedded in resolver expressions

file = require './file'
shell = require './shell'

module.exports = getProcessor = (query) ->
  if query and query.proc and query.proc.name
    switch query.proc.name
      when 'file' then file
      when 'shell' then shell
      else null
  else
    null
