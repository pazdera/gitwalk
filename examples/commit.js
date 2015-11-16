/* A gitwalk example
 *
 * How to add a new file, commit it and push to the upstream repo.
 *
 */

var gitwalk = require('gitwalk'),
    NodeGit = require('nodegit'),
    fs = require('fs'),
    path = require('path');

gitwalk('github:pazdera/scriptster:test', function (repo, done) {
  /* Create a file */
  var fileName = 'DISCLAIMER',
      disclaimerPath = path.join(repo.workdir(), fileName);
  fs.writeFileSync(disclaimerPath, 'THIS IS SPARTA!!!\n');

  var index, oid, branch;

  repo.openIndex()
    .then(function (i) {
      index = i;
      return index.read(1);
    }).then(function () {
      /* Add the new file to the index. */
      return index.addByPath(fileName);
    }).then(function () {
      return index.write();
    }).then(function () {
      return index.writeTree();
    }).then(function (o) {
      /* Note the object id of the tree. */
      oid = o;

      /* Get the id of the current HEAD. */
      return NodeGit.Reference.nameToId(repo, "HEAD");
    }).then(function(head) {
      /* Get the HEAD commit. */
      return repo.getCommit(head);
    }).then(function(parent) {
      var author = NodeGit.Signature.default(repo);
      var committer = NodeGit.Signature.default(repo);

      /* Finalise our commit. */
      return repo.createCommit("HEAD", author, committer,
                               "Adding DISCLAIMER", oid, [parent]);
    }).then(function(o) {
      return repo.getCurrentBranch();
    }).then(function(ref) {
      /* Note the current branch ref. */
      branch = ref.name();

      /* Prepare remote for pushing. */
      return NodeGit.Remote.lookup(repo, 'origin');
    }).then(function(remote) {
      /* Push the changes upstream. */
      var pushOpts = {callbacks: gitwalk.authCallbacks()};
      return remote.push([branch + ':' + branch], pushOpts);
    }).catch(function(err) {
      if (err) {
        done(err);
      }
    }).done(function() {
      done();
    });
}, function (err) {
  if (err) {
    console.log(err);
  }
});
