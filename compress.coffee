fs = require 'fs'
compress = (inputFile, outputFile) ->
  console.log 'starting to compress file ' + inputFile
  fs.readFile inputFile, (err, dataBuffer) ->
    if err
      console.error "Could not open file #{inputFile}"
    else
      console.log "#{inputFile} opened"
      createFrequencyMap dataBuffer, (err, map) ->
        if err
          console.err err
        else
          encode dataBuffer, outputFile, (err, result) ->
            if err
              console.err err
            else
              console.log 'compressing complete'


encode = (dataBuffer, freqMap) ->
  console.log 'encode called'

scaleFrequencyMap = (freqMap, maxValue) ->
  scaled = maxValue / 256.0
  newMap = {}
  sum = 0
  for value, index in freqMap
    if value != undefined
      newValue = parseInt value / scaled
      if newValue <= 0
        newValue = 1
      else if newValue > 255
        console.log '------------------ ' + newValue 
        newValue = 255
      console.log 'key value is ' + index + ' ' + newValue
      newMap[index] = newValue
      sum += newValue
  # TODO: check if sum > 2^14
  if sum >= 16384
    for key, value of newMap
      newMap[key] = parseInt value / 2
  newMap

createFrequencyMap = (dataBuffer, callback) ->
  console.log 'createFrequencyMap() called'
  freqMap = []
  largest = 0
  for index in [0 ... dataBuffer.length]
    byte = dataBuffer.readUInt8 index
    console.log byte
    if freqMap[byte]
      freqMap[byte] += 1
    else
      freqMap[byte] = 1
    if largest < freqMap[byte]
      largest = freqMap[byte]
  callback null, scaleFrequencyMap freqMap, largest

module.exports =
  compress : compress