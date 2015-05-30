should = require('chai').should()

###
describe 'model/spec/readSpec', ->
  it 'shouldn\'t error', ->
    spec.readSpec valid_spec_string, (err, s) ->
      should.not.exist err

  it 'should return an object', ->
    spec.readSpec valid_spec_string, (err, s) ->
      s.should.be.an 'object'
###
