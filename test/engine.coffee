engine = require '../src/lib/engine'
proc = require '../src/lib/processors'

should = require('chai').should()
expect = require('chai').expect


describe 'engine', ->
  it 'should run correctly', (done) ->
    #eng = new engine.Engine 'github:pazdera/tco@.+/.*'
    #eng = new engine.Engine '~/repos/kano-apps@master/kano_apps/*.py'
    eng = new engine.Engine '~/repos/kano-apps@(new-tracker|mast*)',
                            proc.command.generator 'git status'
    #eng = new engine.Engine 'github:pazdera/scriptster:master$', 'git status'
    eng = new engine.Engine 'github:kanocomputing/onboarding:master',
                            proc.command.generator 'git status'
    #eng = new engine.Engine 'github:pazdera/tco@master$'
    #eng.run (repo, done) ->
    #  console.log "Result: #{repo}"
    #  done()
    eng.run done
