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
          compass: true
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
    copy:
      json:
        expand: true
        cwd: 'assets/json/'
        src: [ '**/*.json' ]
        dest: 'public/'
        filter: 'isFile'
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
            'public/bower_components/angular/angular.js'
            'public/bower_components/ng-table/ng-table.js'
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
      json:
        files: 'assets/json/**/*.json'
        tasks: 'copy:json'
    clean:
      assets: [ "public/*", "!public/bower_components" ]
    'http-server':
      assets:
        root: "public/"
        port: 8080
        runInBackground: true

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
  grunt.loadNpmTasks 'grunt-http-server'

  grunt.registerTask 'default', [
    'build'
    'http-server'
    'watch'
  ]

  grunt.registerTask 'build', [
    'coffee:assets'
    'sass:assets'
    'haml:assets'
    'copy:json'
  ]

  grunt.registerTask 'dist', [
    'coffee:assets'
    'ngAnnotate'
    'uglify:dist'
    'sass:assets'
    'cssmin:dist'
    'haml:dist'
  ]
