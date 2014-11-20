serveStatic = require "serve-static"

module.exports = (grunt) ->
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
        expand: true
        cwd: 'assets/html'
        src: [ '**/*.haml' ]
        dest: 'public'
        ext: '.html'
      dist:
        options:
          language: 'coffee'
          context:
            isDist: true
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
            src: [
              'index.js'
              'config.js'
              'controllers/**/*.js'
              'directives/**/*.js'
              'factories/**/*.js'
              'filters/**/*.js'
            ]
            ext: '.annotate.js'
            cwd: 'public'
            dest: 'public'
          }
        ]
    uglify:
      dist:
        files:
          'public/index.min.js': [
            'public/bower_components/jquery/dist/jquery.js'
            'public/bower_components/lodash/dist/lodash.js'
            'public/bower_components/bootstrap-sass-official/assets/javascripts/bootstrap.js'
            'public/bower_components/angular/angular.js'
            'public/bower_components/angular-route/angular-route.js'
            'public/bower_components/angular-bootstrap/ui-bootstrap.js'
            'public/bower_components/angular-bootstrap/ui-bootstrap-tpls.js'
            'public/bower_components/angularjs-dropdown-multiselect/src/angularjs-dropdown-multiselect.js'
            'public/bower_components/moment/moment.js'
            'public/bower_components/async/lib/async.js'
            'public/bower_components/sprintf/src/sprintf.js'
            'public/bower_components/oauth-js/dist/oauth.js'
            'public/index.annotate.js'
            'public/config.annotate.js'
            'public/controllers/**/*.annotate.js'
            'public/directives/**/*.annotate.js'
            'public/factories/**/*.annotate.js'
            'public/filters/**/*.annotate.js'
          ]
    cssmin:
      dist:
        files:
          'public/index.min.css': [
            'public/index.css'
          ]
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
          middleware: [
            [ "/", serveStatic "public" ]
          ]

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
