var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util'),
    coffeelint = require('gulp-coffeelint'),
    mocha = require('gulp-mocha'),
    es = require('event-stream'),
    rename = require("gulp-rename");

require('coffee-script/register');

var srcDir = './src/',
    libDir = './lib/',
    testDir = './test/',
    binDir = './bin/';

gulp.task('lint', function () {
    return gulp.src([srcDir + '*.coffee'])
               .pipe(coffeelint())
               .pipe(coffeelint.reporter());
});

gulp.task('coffee', function() {
    src = gulp.src([srcDir + '*.coffee'])
              .pipe(coffee({bare: true}).on('error', gutil.log))
              .pipe(gulp.dest(libDir));

    bin = gulp.src([binDir + '*.coffee'])
              .pipe(coffee({bare: true}).on('error', gutil.log))
              .pipe(rename(function (path) {
                  path.extname = "";
              }))
              .pipe(gulp.dest(binDir));

    return es.concat(src, bin);
});

gulp.task('test', function() {
    sources = testDir + '*.coffee';
    sources = testDir + 'engine.coffee';

    return gulp.src(sources, {read: false})
               .pipe(mocha({reporter: 'nyan', timeout: 30000}));
});

gulp.task('default', ['lint', 'coffee'], function() {
});
