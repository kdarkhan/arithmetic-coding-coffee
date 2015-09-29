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
          # assert.ok map?.values && map.keys, 'freqMap is not a valid object'
          console.log 'darkhan --------'
          console.dir map
          encode dataBuffer, map, (err, result) ->
            if err
              console.err err
            else
              console.log 'compressing complete'

writeBufferToFile = (buffer, length, filename) ->
  sliceBuffer = buffer.slice 0, length
  stream = fs.createWriteStream filename
  stream.write sliceBuffer
  console.log 'write complete'

writeHeader = (buffer, dictionary, callback) ->
  # write file dictionary and other metadata
  console.log 'Header was written to temp file'
  freqMap.writeDictionary buffer, dictionary, 1, (err, bytesWritten) ->
    buffer.writeUInt8 bytesWritten, 0
    callback null, bytesWritten + 1
decToBin = (num) ->
  (num >>> 0).toString 2
isUnderflow = (low, high) ->
  (low & 0xC000) == (high & 0xC000)
encode = (dataBuffer, freqMap) ->
  # arithmetic encoding algorithm
  console.log 'encode() called'
  buffer = new Buffer Math.max dataBuffer.length * 2, 10000
  writeHeader buffer, freqMap, (err, sizeWritten) ->
    if err
      console.error err
    else
      # TODO: change offset
      # TODO: use separate buffer, not stream
      nextOffset = sizeWritten
      accumulator = 0 
      index = 0
      bitWriter = (bit) ->
        console.log 'bit is ' + bit
        # composes bits to groups of bytes and flushes complete bytes
        accumulator = ( if bit > 0 then 1 else 0 ) + ( accumulator << 1 )
        index += 1
        if index == 8
          console.log 'writing byte ' + accumulator
          buffer.writeUInt8 accumulator, nextOffset
          nextOffset += 1
          index = 0
          accumulator = 0

      highValues = freqMap.highValues
      lowValues = freqMap.lowValues
      scale = freqMap.scale
      console.log 'Starting the actual encoding'
      high = 0xFFFF
      low = 0x0000
      msb = 0x8000
      underflowBits = 0
      finalizeEncoding = (low) ->
        bitWriter low & 0x4000
        while underflowBits-- > 0
          bitWriter ~(low & 0x4000)
        for i in [1..15]
          bitWriter 0
      for i in [0 ... dataBuffer.length]
        # read the character
        byte = dataBuffer.readUInt8 i
        # rearrange the interval
        range = high - low + 1
        high = low + ((range * highValues[byte]) / scale) - 1
        low = low + (range * lowValues[byte]) / scale
        if (msb & low) == (msb & high)
          while (msb & low) == (msb & high)
            nextBit = if (msb & low) > 0 then 1 else 0
            console.log "#{range} #{decToBin high} #{decToBin low} #{decToBin byte}"
            bitWriter nextBit
            while underflowBits > 0
              bitWriter ~nextBit
              underflowBits -= 1
            high = ((high << 1) & 0xFFFF) | 0x0001
            low = (low << 1) & 0xFFFF
        else if isUnderflow low, high
          console.log 'udnerflow found ------------------------------------------------------'
          underflowBits += 1
          low = ( low & 0x3FFF ) << 1
          high = (( high | 0x4000 ) << 1) | 1
      finalizeEncoding low
      writeBufferToFile buffer, nextOffset, TEMP_FILE_NAME

module.exports =
  compress : compress