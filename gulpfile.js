var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util'),
    coffeelint = require('gulp-coffeelint'),
    mocha = require('gulp-mocha'),
    es = require('event-stream'),
    rename = require("gulp-rename"),
    debug = require('gulp-debug'),
    insert = require('gulp-insert');

require('coffee-script/register');

var srcDir = './src/',
    outDir = './out/',
    testDir = './test/';

gulp.task('lint', function () {
    return gulp.src([srcDir + '**/*.coffee'])
               .pipe(coffeelint())
               .pipe(coffeelint.reporter());
});

gulp.task('build', function() {
    src = gulp.src([srcDir + 'lib/**/*.coffee'])
              /*.pipe(debug())*/
              .pipe(coffee({bare: true}).on('error', gutil.log))
              .pipe(gulp.dest(outDir + "/lib"));

    bin = gulp.src([srcDir + 'bin/**/*.coffee'])
              /*.pipe(debug())*/
              .pipe(coffee({bare: true}).on('error', gutil.log))
              .pipe(insert.prepend("#!/usr/bin/env node\n\n"))
              .pipe(gulp.dest(outDir + "/bin"));

    return es.concat(src, bin);
});

gulp.task('test', function() {
    sources = testDir + '**.coffee';
    //sources = testDir + 'engine.coffee';

    return gulp.src(sources, {read: false})
               .pipe(mocha({reporter: 'nyan', timeout: 30000}));
});

gulp.task('default', ['lint', 'compile'], function() {
});
