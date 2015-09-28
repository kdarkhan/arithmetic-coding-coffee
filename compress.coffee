assert = require 'assert'
fs = require 'fs'
freqMap = require './frequencyMap'
bs = require 'binary-search'

TEMP_FILE_NAME = './compress.temp.swp'
compress = (inputFile, outputFile) ->
  console.log 'starting to compress file ' + inputFile
  fs.readFile inputFile, (err, dataBuffer) ->
    if err
      console.error "Could not open file #{inputFile}"
    else
      console.log "#{inputFile} opened"
      freqMap.createFrequencyMap dataBuffer, (err, map) ->
        if err
          console.err err
        else
          assert.ok map?.values && map.keys, 'freqMap is not a valid object'
          encode dataBuffer, map, (err, result) ->
            if err
              console.err err
            else
              console.log 'compressing complete'

writeHeader = (fileBuffer, freqMap, callback) ->
  console.log 'Header was written to temp file'
  callback null
encode = (dataBuffer, freqMap) ->
  console.log 'encode() called'
  buffer = fs.createWriteStream TEMP_FILE_NAME
  writeHeader buffer, freqMap, (err) ->
    if err
      console.error err
    else
      keys = freqMap.keys
      values = freqMap.values
      console.log 'Starting the actual encoding'
      high = 0xFFFF
      low = 0x0000
      underflowBits = 0

module.exports =
  compress : compress