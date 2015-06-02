# Processor mappings for purposes of matching the ones
# embedded in resolver expressions

file = require './processors/file'

exports.getProcessor = (query) ->
  return null unless query.proc

  switch query.proc.name
    when 'file' then file
    else null
