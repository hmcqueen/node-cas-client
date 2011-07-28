exec = require('child_process').exec

task 'build', ->
  exec 'coffee -b -o lib -c src/*.coffee', (err) ->
    console.log err if err
