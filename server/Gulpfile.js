var gulp = require("gulp");
var sourcemaps = require("gulp-sourcemaps");
var babel = require("gulp-babel");
var concat = require("gulp-concat");
var watch = require("gulp-watch");
var plumber = require("gulp-plumber");

gulp.task("babel", function () {
	return gulp.src("src/**/*.js")
		.pipe(plumber())
		.pipe(sourcemaps.init())
		.pipe(babel())
		.on("error", function(error) {
			console.error(error.message);
		})
		.pipe(sourcemaps.write("."))
		.pipe(gulp.dest("dist"));
});

gulp.task("watch", function() {
	gulp.watch("src/**/*.js", ["babel"]);
});

gulp.task("default", ["babel", "watch"]);