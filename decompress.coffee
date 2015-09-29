freqMap = require './frequencyMap'
fs = require 'fs'

readFile = (inputFile, callback) ->
  console.log 'readFile() called'
  fs.readFile inputFile, (err, buffer) ->
    if err
      callback err
    else
      dictSize = parseInt (buffer.readUInt8 0) / 2
      freqMap.parseDictionary buffer, 1, dictSize, (err, res) ->
        if err
          callback err
        else
          callback null, res, buffer

decompress = (inputFile, outputFile) ->
  # TODO: remove this line
  inputFile = 'compress.temp.swp'
  console.log 'decompress is called'
  readFile inputFile, (err, dictionary, buffer) ->
    if err
      console.error err
    else
      console.log 'readFile returned'


module.exports =
  decompress: decompress