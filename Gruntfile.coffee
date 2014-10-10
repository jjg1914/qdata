module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      assets:
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
            "public/bower_components/bootstrap-sass-official/assets/stylesheets/"
            "public/bower_components/font-awesome/scss/"
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
        files:
          'public/index.annotate.js': [ 'public/index.js' ]
    uglify:
      dist:
        files:
          'public/index.min.js': [
            'public/bower_components/jquery/dist/jquery.js'
            'public/bower_components/bootstrap-sass-official/assets/javascripts/bootstrap.js'
            'public/bower_components/angular/angular.js'
            'public/bower_components/angular-route/angular-route.js'
            'public/bower_components/ng-table/ng-table.js'
            'public/bower_components/moment/moment.js'
            'public/bower_components/async/lib/async.js'
            'public/bower_components/sprintf/src/sprintf.js'
            'public/index.annotate.js'
          ]
    cssmin:
      dist:
        files:
          'public/index.min.css': [
            'public/bower_components/ng-table/ng-table.css'
            'public/index.css'
          ]
    watch:
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
    'http-server':
      assets:
        root: "public/"
        port: 8080
        runInBackground: true
      dist:
        root: "public/"
        port: 8080

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
  grunt.loadNpmTasks 'grunt-http-server'

  grunt.registerTask 'default', [
    'build'
    'http-server:assets'
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
