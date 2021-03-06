assert = require 'assert'
freqMap = require './frequencyMap'
fs = require 'fs'
digest = require './digest'

MAX_BUFFER_SIZE = 10000000

logger = if process.verbose then console.log else ->

binarySearch = (array, obj, entry) ->
  # optimize this to make binary search
  for value, index in array
    if entry < obj[value] && ((index > 0 && obj[array[index - 1]] <= entry) || (index == 0))
      logger 'found index ' + index  + ' for entry ' + entry
      return value
  throw new Error "Value is not found with such probability #{entry}"

readFile = (inputFile, callback) ->
  logger 'readFile() called'
  fs.readFile inputFile, (err, buffer) ->
    if err
      callback err
    else
      dictEntries = 1 + parseInt (buffer.readUInt8 0)
      filesize = parseInt (buffer.readUInt32LE 1)
      dictSize = dictEntries * 2
      digestBuffer = buffer.slice 5 + dictSize, 5 + dictSize + 16
      freqMap.parseDictionary buffer, 5, dictEntries, (err, res) ->
        if err
          callback err
        else
          callback null, res, buffer, 16 + 5 + dictSize, filesize, digestBuffer

isUnderflow = (low, high) ->
  (low & 0x4000) && !(high & 0x4000)

decToBin = (num) ->
  (num >>> 0).toString 2

writeBufferToFile = (buffer, filename, digestBuffer) ->
  filename = filename || 'test.out'
  console.log "Saving file to #{filename}"
  fs.writeFile filename, buffer, (err, res) ->
    if err
      console.error 'could not write to file'
      console.error err
    else
      console.log 'file was written'
      digest.md5verify buffer, digestBuffer
decompress = (inputFile, outputFile) ->
  # TODO: remove this line
  logger 'decompress is called'
  readFile inputFile, (err, dictionary, buffer, startOffset, filesize, digestBuffer) ->
    if err
      console.error err
    else
      logger "starting decompression #{buffer.length} #{startOffset}"
      outBuffer = new Buffer MAX_BUFFER_SIZE
      outBufferIndex = 0
      shiftCount = 0
      offset = startOffset
      lowValues = dictionary.lowValues
      logger lowValues
      highValues = dictionary.highValues
      keys = dictionary.keys
      logger 'low values are ', lowValues
      logger 'keys are ', keys
      scale = dictionary.scale
      high = 0xFFFF
      low = 0x0000
      msb = 0x8000
      code = ((buffer.readUInt8 offset) << 8) | (buffer.readUInt8 offset + 1)
      nextCode = ((buffer.readUInt8 offset + 2) << 8) | (buffer.readUInt8 offset + 3)
      logger 'file size is ---------------------------- file size is ' + filesize 
      while outBufferIndex < filesize 
        logger 'current offset is ' + offset
        range = high - low + 1
        temp = ((((code - low) + 1) * scale - 1) / range ) & 0xFFFF
        byte = binarySearch keys, highValues, temp
        outBuffer.writeUInt8 byte, outBufferIndex++
        # find new high and low
        high = (low + ((range * highValues[byte]) / scale) - 1) & 0xFFFF
        low = (low + (range * lowValues[byte] / scale)) & 0xFFFF
        logger "low high is #{scale} ===== #{decToBin low} #{decToBin high} --- #{highValues[byte]} #{lowValues[byte]}"
        assert.ok low < high, "Low should be smaller than high #{highValues[byte]} #{high} #{scale} #{range}"

        # shift logic
        while true
          if (msb & high) == (msb & low)
            # do nothing
            0
          else if isUnderflow low, high
            low = low & 0x3FFF
            high = high | 0x4000
            code = code ^ 0x4000
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
            # check if buffer is finished
            if offset + 3 < buffer.length
              nextCode = ((buffer.readUInt8 offset + 2) << 8) | (buffer.readUInt8 offset + 3) 
            else if offset + 2 < buffer.length
              nextCode = ((buffer.readUInt8 offset + 2) << 8)
            else
              break
              # nextCode = 0
      writeBufferToFile (outBuffer.slice 0, outBufferIndex), outputFile, digestBuffer

module.exports =
  decompress: decompress