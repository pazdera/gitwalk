#
# The selector implementation for GitHub
#
# The expression looks like this:
#
#   github:$user/$repo:$branch/$path


minimatch = require 'minimatch'
GitHubApi = require 'github'
config = require '../config'
utils = require '../utils'
logger = require '../logger'


class exports.GitHub
  constructor: (expression) ->
    match = @parseExpression expression

    logger.debug "GitHub: #{match[1]}/#{match[2]}, branch #{match[4]}"

    @user = match[1]
    @repoRe = minimatch.makeRe match[2]

    match[4] ?= 'master'
    @branchRe = minimatch.makeRe match[4]

    @repos = []

    @api = new GitHubApi {
      version: '3.0.0'
    }

    if config.get 'resolvers:github:token'
      @api.authenticate
        type: "oauth",
        token: config.get 'resolvers:github:token'
    else if config.get('resolvers:github:username') and
            config.get('resolvers:github:password')
      @api.authenticate
        type: "basic"
        username: config.get 'resolvers:github:username'
        password: config.get 'resolvers:github:password'
     else
       logger.debug 'No GitHub authentication'


  parseExpression: (expression) ->
    pattern = ///
      ^github\:
      ([a-zA-Z0-9\-_]+)\/ # user
      ([^:]+)             # repository
      (\:(.+))?           # optional branch (master assumed if not set)
    ///

    match = expression.match pattern

    unless match
      throw new Error 'This isn\'t a valid GitHub expression.'

    match

  getReposFromOrg: (org, page, callback) ->
    # making page optional
    if !callback
      callback = page
      page = 1
      @repos = []
    else
      page = page || 1

    @api.repos.getFromOrg {org: org, page: page, type: 'all'}, (err, data) =>
      if err
        callback err, null
        return

      if data.length
        logger.debug "Listing repositories of #{org}: page ##{page}"
        Array::push.apply @repos, data
        page++
        @getReposFromOrg org, page, callback
      else
        callback null, @repos

  getReposFromUser: (user, page, callback) ->
    # making page optional
    if !callback
      callback = page
      page = 1
      @repos = []
    else
      page = page || 1

    @api.repos.getFromUser {user: user, page: page}, (err, data) =>
      if err
        callback err, null
        return

      if data.length
        logger.debug "Listing repositories of #{user}: page ##{page}"
        Array::push.apply @repos, data
        page++
        @getReposFromUser user, page, callback
      else
        callback null, @repos

  resolve: (callback) ->
    @api.user.getFrom {user: @user}, (err, data) =>
      if err
        callback "Unable to retrieve '#{@user}': #{err.message}", null
        return

      unless data
        callback "User '#{@user}' not found on GitHub.", null
        return

      if data.type == "Organization"
        @getReposFromOrg @user, (err, data) =>
          @process_repos err, data, callback
      else
        @getReposFromUser @user, (err, data) =>
          @process_repos err, data, callback


  process_repos: (err, repo_handles, callback) ->
    if err
      callback err, null
      return

    unless repo_handles.length
      callback "No repositories found for '#{@user}'", null
      return

    engineQueries = []
    for repo in repo_handles
      if @repoRe.test repo.name
        query =
          name: repo.name,
          urls: [repo.ssh_url, repo.clone_url, repo.git_url],
          branchRe: @branchRe

        engineQueries.push query

    if engineQueries.length
      callback null, engineQueries
    else
      callback "No repositories match this expression '#{@repoRe}'", null

# Quickly check whether a string could be a github expression
#
# @param [String] expression The expression to test.
#
# @return [Boolean] True when the expression matches.
#
exports.test = (expression) ->
  /^github\:/.test expression
