assert = require 'assert'
freqMap = require './frequencyMap'
fs = require 'fs'

binarySearch = (array, obj, entry) ->
  # optimize this to make binary search
  for value, index in array
    if entry < obj[value] && ((index > 0 && obj[array[index - 1]] <= entry) || (index == 0))
      console.log 'found index ' + index  + ' for entry ' + entry
      return value
  throw new Error "Value is not found with such probability #{entry}"

readFile = (inputFile, callback) ->
  console.log 'readFile() called'
  fs.readFile inputFile, (err, buffer) ->
    if err
      callback err
    else
      dictSize = parseInt (buffer.readUInt8 0)
      dictEntries = dictSize / 2
      freqMap.parseDictionary buffer, 1, dictEntries, (err, res) ->
        if err
          callback err
        else
          callback null, res, buffer, 1 + dictSize

isUnderflow = (low, high) ->
  (low & 0xC000) == (high & 0xC000)

decompress = (inputFile, outputFile) ->
  # TODO: remove this line
  inputFile = 'compress.temp.swp'
  console.log 'decompress is called'
  readFile inputFile, (err, dictionary, buffer, startOffset) ->
    if err
      console.error err
    else
      console.log "starting decompression #{buffer.length} #{startOffset}"
      shiftCount = 0
      offset = startOffset
      lowValues = dictionary.lowValues
      console.dir lowValues
      highValues = dictionary.highValues
      keys = dictionary.keys
      console.log 'high values is '
      console.dir highValues
      console.dir keys
      scale = dictionary.scale
      high = 0xFFFF
      low = 0x0000
      msb = 0x8000
      code = ((buffer.readUInt8 offset) << 8) | (buffer.readUInt8 offset + 1)
      nextCode = ((buffer.readUInt8 offset + 2) << 8) | (buffer.readUInt8 offset + 3)
      while offset <= buffer.length - 20
        range = high - low + 1
        temp = (((code - low) + 1) * scale - 1) / range
        byte = binarySearch keys, highValues, temp
        console.log 'sym is  ' + byte
        # find new high and low
        high = (low + ((range * highValues[byte]) / scale) - 1) & 0xFFFF
        low = (low + (range * lowValues[byte] / scale)) & 0xFFFF
        console.log "low high is #{low} #{high}"
        # assert.ok low < high, "Low should be smaller than high #{highValues[byte]} #{high} #{scale} #{range}"

        # shift logic
        while true
          if (msb & high) == (msb & low)
            # do nothing
            null 
          else if isUnderflow low, high
            low = low & 0x3FFF
            high = high | 4000
            code = code ^ 4000
          else
            break
          low = (low << 1) & 0xFFFF
          high = (high << 1) & 0xFFFF | 0x0001
          code = (code << 1) & 0xFFFF | ((nextCode & msb) >>> 15)
          nextCode = (nextCode << 1) & 0xFFFF
          shiftCount += 1
          if shiftCount >= 16
            shiftCount = 0
            offset += 2
            nextCode = ((buffer.readUInt8 offset + 2) << 8) & (buffer.readUInt8 offset + 3) 

module.exports =
  decompress: decompress