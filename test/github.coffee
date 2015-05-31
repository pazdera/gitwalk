github = require '../src/resolvers/github'

should = require('chai').should()
expect = require('chai').expect


describe 'resolvers.github.test', ->
  it 'should match expression', ->
    expect github.test 'github:pazdera/.*'
      .to.be.equal true

  it 'should not match expression', ->
    expect github.test 'http://github.com/pazdera/.*'
      .to.not.be.equal true


describe 'resolvers.github.Github', ->
  describe '.resolve', ->
    it 'existing account should resolve fine', (done) ->
      gh = new github.GitHub 'github:pazdera/.*'
      gh.resolve (err, data) ->
        expect(err).to.be.equal null
        expect(data.length).to.be.above 0
        #console.log data
        done()

    it 'user with not repos should return error', (done) ->
      # This test depends on the teamkano user to have 0 repositories.
      # If that changes, this needs to be fixed.
      gh = new github.GitHub 'github:teamkano/.*'
      gh.resolve (err, data) ->
        expect(err).to.not.be.null
        expect(data).to.be.null
        done()

    it 'should fail when the user doesn\'t exist', (done) ->
      # This test depends on the user bellow not to exist.
      # If that changes, this needs to be fixed.
      gh = new github.GitHub 'github:xetrcytvuybiuygutfyvgbhbvtcyf/.*'
      gh.resolve (err, data) ->
        expect(err).to.not.be.null
        expect(data).to.be.null
        done()

    it 'should fail when the repo_re doesn\'t match aything', (done) ->
      gh = new github.GitHub 'github:pazdera/DOES_NOT_EXIST'
      gh.resolve (err, data) ->
        expect(err).to.not.be.null
        expect(data).to.be.null
        done()

    it 'parses string branch correctly', (done) ->
      gh = new github.GitHub 'github:pazdera/tco@master'
      gh.resolve (err, data) ->
        expect(err).to.be.null
        expect(data[0].branch_re.source).to.be.equal 'master'
        done()

    it 'parses re branch correctly', (done) ->
      gh = new github.GitHub 'github:pazdera/tco@.+'
      gh.resolve (err, data) ->
        expect(err).to.be.null
        expect(data[0].branch_re.source).to.be.equal '.+'
        done()

    it 'parses the file processor correctly', (done) ->
      gh = new github.GitHub 'github:pazdera/tco/.*'
      gh.resolve (err, data) ->
        expect(err).to.be.null
        expect(data[0].proc.name).to.be.equal 'file'
        expect(data[0].proc.args[0].source).to.be.equal '.*'
        done()
