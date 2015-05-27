var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util');

gulp.task('coffee', function() {
    gulp.src('./src/*.coffee')
        .pipe(coffee({bare: true}).on('error', gutil.log))
        .pipe(gulp.dest('./lib/'));
});

gulp.task('test', ['coffee'], function() {
    console.log('No tests implemented yet.');
});

gulp.task('default', ['coffee'], function() {
});
