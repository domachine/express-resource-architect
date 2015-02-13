module.exports = (grunt) ->
  require('load-grunt-tasks') grunt

  pages = [
    'index'
    'getting-started'
    'api'
  ]

  grunt.initConfig
    jade:
      options:
        pretty: true
        data: (dest, src) ->
          filename: dest
      pages:
        files: do ->
          opts = {}
          for page in pages
            opts["#{page}.html"] = "src/#{page}.jade"
          opts
    less:
      main:
        files:
          './css/index.css': ['src/less/index.less']
    watch:
      pages:
        files: ['src/**/*.jade', 'src/**/*.md']
        tasks: ['jade:pages']
      css:
        files: ['src/less/**/*']
        tasks: ['less:main']

  grunt.registerTask 'build', ['jade', 'less']
