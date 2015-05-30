var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util'),
    coffeelint = require('gulp-coffeelint'),
    mocha = require('gulp-mocha');

require('coffee-script/register');

var srcDir = './src/',
    libDir = './lib/',
    testDir = './test/';

gulp.task('lint', function () {
    gulp.src([srcDir + '*.coffee', srcDir + '*/*.coffee'])
        .pipe(coffeelint())
        .pipe(coffeelint.reporter());
});

gulp.task('coffee', function() {
    gulp.src(srcDir + '*.coffee')
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest(libDir));
});

gulp.task('test', function() {
    gulp.src(testDir + '*.coffee', {read: false})
        .pipe(mocha({reporter: 'nyan'}));
});

gulp.task('default', ['lint', 'coffee'], function() {
});
