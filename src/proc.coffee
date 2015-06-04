# Processor mappings for purposes of matching the ones
# embedded in resolver expressions

file = require './processors/file'
shell = require './processors/shell'

exports.getProcessorByName = (procName) ->
  return null unless procName

  switch procName
    when 'file' then file
    when 'shell' then shell
    else null
