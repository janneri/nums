path       = require 'path'
gulp       = require 'gulp'
gutil      = require 'gulp-util'
jade       = require 'gulp-jade'
stylus     = require 'gulp-stylus'
CSSmin     = require 'gulp-minify-css'
browserify = require 'gulp-browserify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
coffeeify  = require 'coffeeify'
lr         = require 'tiny-lr'
livereload = require 'gulp-livereload'
express    = require 'express'
http       = require 'http'

reloadServer = lr()

compileCoffee = (debug = false) ->
  bundle = gulp
    .src('./src/coffee/main.coffee', read: false)
    .pipe(browserify(debug: debug))
    .pipe(rename('bundle.js'))

  bundle.pipe(uglify()) unless debug

  bundle
    .pipe(gulp.dest('./public/js/'))
    .pipe(livereload(reloadServer))

compileJade = (debug = false) ->
  gulp
    .src('src/jade/*.jade')
    .pipe(jade(pretty: debug))
    .pipe(gulp.dest('public/'))
    .pipe livereload(reloadServer)

compileStylus = (debug = false) ->
  styles = gulp
    .src('src/stylus/style.styl')
    .pipe(stylus({set: ['include css']}))

  styles.pipe(CSSmin()) unless debug

  styles.pipe(gulp.dest('public/css/'))
    .pipe livereload reloadServer

copyAssets = (debug = false) ->
  gulp
    .src('src/assets/**/*.*')
    .pipe gulp.dest 'public/'

# Build tasks
gulp.task "jade-production", -> compileJade()
gulp.task 'stylus-production', ->compileStylus()
gulp.task 'coffee-production', -> compileCoffee()
gulp.task 'assets-production', -> copyAssets()

# Development tasks
gulp.task "jade", -> compileJade(true)
gulp.task 'stylus', -> compileStylus(true)
gulp.task 'coffee', -> compileCoffee(true)
gulp.task 'assets', -> copyAssets(true)

translate = (req, res, str) ->
  console.log("getting translation for " + str)
  lang = 'fi'

  httpOptions = {
      hostname: 'translate.google.com',
      path: '/translate_tts?ie=UTF-8&q=' + str + '&tl=' + lang + '&total=1&idx=0&prev=input'
  }

  reqGet = http.request httpOptions, (response) ->
      if response.statusCode == 404 or response.statusCode == 403
        console.log("error")
      else
          idx = 0;
          len = parseInt(response.headers["content-length"])
          body = new Buffer(len);

          response.setEncoding('binary');

          response.on 'data', (chunk) ->
              body.write(chunk, idx, "binary");
              idx += chunk.length;
      
          response.on 'end', () -> 
            res.setHeader('Content-Type', 'audio/mpeg')
            res.setHeader('Content-Length', len)
            res.setHeader('Content-Range', 'bytes 0-' + (len-1) + '/' + len)
            res.send(body)

  reqGet.on 'error', (e) -> 
      console.log("on error")

  reqGet.end()


serve = ->  
  app = express()
  app.use(express.static(__dirname + '/public'))
  
  app.get '/translate/:str', (req, res) -> 
    translate(req, res, req.params.str)

  app.listen(process.env.PORT || 9001)

gulp.task "server", -> serve()

gulp.task "watch", ->
  reloadServer.listen 35729, (err) ->
    console.error err if err?

    gulp.watch "src/coffee/*.coffee", ["coffee"]
    gulp.watch "src/jade/*.jade", ["jade"]
    gulp.watch "src/stylus/*.styl", ["stylus"]
    gulp.watch "src/assets/**/*.*", ["assets"]

gulp.task "build", ["coffee-production", "jade-production", "stylus-production", "assets-production"]
gulp.task "default", ["coffee", "jade", "stylus", "assets", "watch", "server"]
