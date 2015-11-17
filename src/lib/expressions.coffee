# Expression-related functions

async = require 'async'

logger = require './logger'
utils = require './utils'

class exports.ExpressionSet
  constructor: (@expressions, @getResolver) ->
    if !(@expressions instanceof Array)
      @expressions = [@expressions]

    @resolvers =
      include: []
      exclude: []

    @queries = []

  getQueries: (callback) ->
    async.eachSeries @expressions, ((exp, done) =>
      bucket = @resolvers.include
      if exp[0] == '^'
        exp = exp.slice 1
        bucket = @resolvers.exclude

      bucket.push @getResolver exp
      done()
    ),
    (err) =>
      return callback err if err?
      @includeQueries (err) =>
        return callback err if err?
        @excludeQueries (err) =>
          return callback err if err?
          callback null, @queries

  includeQueries: (callback) ->
    async.eachSeries @resolvers.include, ((res, done) =>
      res.resolve (err, queries) =>
        return done err if err?
        for newQuery in queries
          addQuery = true
          for newUrl in newQuery.urls
            for oldQuery in @queries
              if newUrl in oldQuery.urls
                addQuery = false
                break
            break if !addQuery
          @queries.push newQuery if addQuery
        done()
    ), callback

  excludeQueries: (callback) ->
    async.eachSeries @resolvers.exclude, ((res, done) =>
      res.resolve (err, queries) =>
        return done err if err?
        for newQuery in queries
          #if newQuery.branchRe.source != 'master'
          #  logger.warn "Branches on exclude queries are ignored"
          for newUrl in newQuery.urls
            rmQuery = null
            for oldQuery in @queries
              if newUrl in oldQuery.urls
                rmQuery = oldQuery
                break
            if rmQuery
              idx = @queries.indexOf rmQuery
              @queries.splice(idx, 1)
        done()
    ), callback
