assert = require 'assert'
fs = require 'fs'
freqMap = require './frequencyMap'
bs = require 'binary-search'


logger = console.log
logger = ->


TEMP_FILE_NAME = './compress.temp.swp'
compress = (inputFile, outputFile) ->
  logger 'starting to compress file ' + inputFile
  fs.readFile inputFile, (err, dataBuffer) ->
    if err
      console.error "Could not open file #{inputFile}"
    else
      logger "#{inputFile} opened"
      freqMap.createFrequencyMap dataBuffer, (err, map) ->
        if err
          console.err err
        else
          console.dir map
          encode dataBuffer, map, outputFile, (err, result) ->
            if err
              console.err err
            else
              logger 'compressing complete'

writeBufferToFile = (buffer, length, filename) ->
  sliceBuffer = buffer.slice 0, length
  stream = fs.createWriteStream filename
  stream.end sliceBuffer
  logger "file #{filename} was written"

writeHeader = (buffer, dictionary, filesize, callback) ->
  # write file dictionary and other metadata
  # first byte is dictionary size
  # first word starting at offset 1 is decompressed size
  freqMap.writeDictionary buffer, dictionary, 5, (err, bytesWritten) ->
    console.log 'Header was written to temp file ' + bytesWritten
    buffer.writeUInt8 (parseInt bytesWritten / 2) - 1, 0
    buffer.writeUInt32LE filesize, 1
    callback null, bytesWritten + 5

decToBin = (num) ->
  (num >>> 0).toString 2
isUnderflow = (low, high) ->
  (low & 0x4000) && !(high & 0x4000)
encode = (dataBuffer, freqMap, outputFile, callback) ->
  # arithmetic encoding algorithm
  logger 'encode() called'
  buffer = new Buffer Math.max dataBuffer.length * 2, 10000
  writeHeader buffer, freqMap, dataBuffer.length, (err, sizeWritten) ->
    if err
      console.error err
    else
      nextOffset = sizeWritten
      accumulator = 0 
      index = 0
      bitWriter = (bit) ->
        logger 'bit is ' + bit
        # composes bits to groups of bytes and flushes complete bytes
        accumulator = ( if bit > 0 then 1 else 0 ) | ( accumulator << 1 )
        index += 1
        if index == 8
          logger 'writing byte ' + accumulator
          buffer.writeUInt8 accumulator, nextOffset
          nextOffset += 1
          index = 0
          accumulator = 0

      highValues = freqMap.highValues
      lowValues = freqMap.lowValues
      scale = freqMap.scale
      logger 'Starting the actual encoding'
      high = 0xFFFF
      low = 0x0000
      msb = 0x8000
      underflowBits = 0
      finalizeEncoding = (low) ->
        bitWriter low & 0x4000
        while underflowBits > 0
          underflowBits -= 1
          bitWriter (low & 0x4000) != 0
        if index > 0
          accumulator = accumulator << (8 - index)
          buffer.writeUInt8 accumulator, nextOffset
          nextOffset += 1
          index = 0
          accumulator = 0
        
      logger "buffer length is --------------- is  #{dataBuffer.length}"
      for i in [0 ... dataBuffer.length]
        logger 'reading from buffer -------------- ' + i
        # read the character
        byte = dataBuffer.readUInt8 i
        # rearrange the interval
        range = high - low + 1
        high = (low + ((range * highValues[byte]) / scale) - 1) & 0xFFFF
        low = (low + (range * lowValues[byte] / scale)) & 0xFFFF
        logger "HIGH - LOW is #{decToBin high} - #{decToBin low}"
        while true
          if (msb & low) == (msb & high)
            nextBit = if (msb & low) > 0 then 1 else 0
            # logger "#{range} #{decToBin high} #{decToBin low} #{decToBin byte}"
            bitWriter nextBit
            while underflowBits > 0
              underflowBits -= 1
              bitWriter nextBit ^ 1
          else if isUnderflow low, high
            logger 'underflow detected =============================================================='
            underflowBits += 1
            low = low & 0x3FFF
            high = high | 0x4000
          else
            break
          high = ((high << 1) & 0xFFFF) | 0x0001
          low = (low << 1) & 0xFFFF
        assert.ok low < high, 'low should be less than high'
      finalizeEncoding low
      writeBufferToFile buffer, nextOffset + 1, outputFile

module.exports =
  compress: compress