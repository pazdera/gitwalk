var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util'),
    coffeelint = require('gulp-coffeelint');

var srcDir = './src/',
    libDir = './lib/';

gulp.task('lint', function () {
    gulp.src(srcDir + '*.coffee')
        .pipe(coffeelint())
        .pipe(coffeelint.reporter());
});

gulp.task('coffee', function() {
    gulp.src(srcDir + '.coffee')
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest(libDir));
});

gulp.task('test', ['coffee'], function() {
    console.log('No tests implemented yet.');
});

gulp.task('default', ['lint', 'coffee'], function() {
});
