mainBowerFiles =  require "main-bower-files"
serveStatic =     require "serve-static"

_srcSort = (a,b) ->
  [ aSplit, bSplit ] = [ a.split("/"), b.split("/") ]
  if aSplit.length < bSplit.length
    -1
  else if bSplit.length < aSplit.length
    1
  else
    aLast = aSplit[aSplit.length - 1]
    bLast = bSplit[bSplit.length - 1]
    if aLast == "index.js" and bLast != "index.js"
      -1
    else if aLast != "index.js" and bLast == "index.js"
      1
    else
      a.localeCompare(b)

module.exports = (grunt) ->
  deps = for dep in mainBowerFiles() when /\.js$/.test(dep)
    dep.substr((__dirname + "/" ).length)
  srcJS = for src in grunt.file.expand { cwd: "assets/js" }, "**/*.coffee"
    src.replace /\.coffee$/, '.js'
  srcJS.sort _srcSort
  srcJSAn = for src in srcJS
    src.replace /\.js$/, '.annotate.js'
  srcCSS = for src in grunt.file.expand { cwd: "assets/css" }, "**/*.sass"
    src.replace /\.sass$/, '.css'
  srcCSS.sort _srcSort

  grunt.initConfig
    coffee:
      assets:
        options:
          sourceMap: true
        expand: true
        cwd: 'assets/js'
        src: [ '**/*.coffee' ]
        dest: 'public'
        ext: '.js'
    sass:
      assets:
        options:
          bundleExec: true
          compass: true
          loadPath: [
            "public/bower_components/"
          ]
        expand: true
        cwd: 'assets/css'
        src: [ '**/*.sass' ]
        dest: 'public'
        ext: '.css'
    haml:
      assets:
        options:
          language: 'coffee'
          context:
            jsFiles: (dep.replace(/^public\//,"") for dep in deps).concat(srcJS)
            cssFiles: srcCSS
        expand: true
        cwd: 'assets/html'
        src: [ '**/*.haml' ]
        dest: 'public'
        ext: '.html'
      dist:
        options:
          language: 'coffee'
          context:
            jsFiles: [ "index.min.js" ]
            cssFiles: [ "index.min.css" ]
        expand: true
        cwd: 'assets/html'
        src: [ '**/*.haml' ]
        dest: 'public'
        ext: '.html'
    yaml:
      assets:
        expand: true
        cwd: 'assets/json/'
        src: [ '**/*.yaml' ]
        dest: 'public/'
        ext: '.json'
      dist:
        options:
          space: 0
        expand: true
        cwd: 'assets/json/'
        src: [ '**/*.yaml' ]
        dest: 'public/'
        ext: '.json'
    copy:
      fonts:
        files: [
          {
            expand: true
            cwd: "public/bower_components/font-awesome"
            src: [ "fonts/**" ]
            dest: "public/"
          }
          {
            expand: true
            cwd: "public/bower_components/bootstrap-sass-official/assets"
            src: [ "fonts/**" ]
            dest: "public/"
          }
        ]
    ngAnnotate:
      options:
        singleQuotes: true
      dist:
        files: [
          {
            expand: true
            src: srcJS
            ext: '.annotate.js'
            cwd: 'public'
            dest: 'public'
          }
        ]
    uglify:
      dist:
        files:
          'public/index.min.js': deps.concat("public/" + e for e in srcJSAn)
    cssmin:
      dist:
        files:
          'public/index.min.css': ("public/" + e for e in srcCSS)
    watch:
      options:
        livereload: true
      gruntfile:
        files: 'Gruntfile.coffee'
        tasks: 'build'
      coffee:
        files: 'assets/js/**/*.coffee'
        tasks: 'coffee:assets'
      sass:
        files: 'assets/css/**/*.sass'
        tasks: 'sass:assets'
      haml:
        files: 'assets/html/**/*.haml'
        tasks: 'haml:assets'
      yaml:
        files: 'assets/json/**/*.yaml'
        tasks: 'yaml:assets'
    clean:
      assets: [ "public/*", "!public/bower_components" ]
    connect:
      assets:
        options:
          port: 8080
          base: "public/"
          livereload: true
          middleware: [
            [ "/assets", serveStatic "assets" ]
            [ "/", serveStatic "public" ]
          ]
      dist:
        options:
          port: 8080
          base: "public/"
          keepalive: true

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-haml'
  grunt.loadNpmTasks 'grunt-ng-annotate'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-yaml'
  grunt.loadNpmTasks 'grunt-contrib-connect'

  grunt.registerTask 'default', [
    'build'
    'connect:assets'
    'watch'
  ]

  grunt.registerTask 'build', [
    'copy:fonts'
    'coffee:assets'
    'sass:assets'
    'haml:assets'
    'yaml:assets'
  ]

  grunt.registerTask 'dist', [
    'copy:fonts'
    'coffee:assets'
    'ngAnnotate'
    'uglify:dist'
    'sass:assets'
    'cssmin:dist'
    'haml:dist'
    'yaml:dist'
  ]
