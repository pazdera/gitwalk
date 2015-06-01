engine = require '../src/engine'

should = require('chai').should()
expect = require('chai').expect

describe 'engine', ->
  it 'should run correctly', () ->
    eng = new engine.Engine 'github:pazdera/tco@.*/.*'
    eng.run (repo) ->
      console.log "Result: #{repo}"
