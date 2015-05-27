# The main of this module

module.exports = gitwalk = (repo_expr, callback) ->
  callback repo_select repo_expr
