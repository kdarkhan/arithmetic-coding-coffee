
scaleFrequencyMap = (freqMap, maxValue) ->
  scaled = maxValue / 256.0
  newMap = {}
  keyArray = []
  sum = 0
  for value, index in freqMap
    if value != undefined
      newValue = parseInt value / scaled
      if newValue <= 0
        newValue = 1
      else if newValue > 255
        newValue = 255
      newMap[index] = newValue
      keyArray.push index
      sum += newValue
  # TODO: check if sum > 2^14
  if sum >= 16384
    for key, value of newMap
      newMap[key] = parseInt value / 2
    sum = parseInt sum / 2
  highValues = {}
  lowValues = {}
  lastSum = 0
  keyArray.forEach (key) ->
    lowValues[key] = lastSum
    highValues[key] = lastSum + newMap[key]
    lastSum += newMap[key]
  highValues: highValues
  lowValues: lowValues
  scale: sum

createFrequencyMap = (dataBuffer, callback) ->
  console.log 'createFrequencyMap() called'
  freqMap = []
  largest = 0
  for index in [0 ... dataBuffer.length]
    byte = dataBuffer.readUInt8 index
    if byte of freqMap
      freqMap[byte] += 1
    else
      freqMap[byte] = 1
    if largest < freqMap[byte]
      largest = freqMap[byte]
  callback null, scaleFrequencyMap freqMap, largest

writeDictionary = (buffer, freqMap, startOffset, callback) ->
  nextOffset = startOffset
  highValues = freqMap.highValues
  lowValues = freqMap.lowValues
  keys = Object.keys highValues
  # sort keys array as it is not guaranteed to be in order
  keys.sort (a, b) ->
    highValues[a] - highValues[b]
  for key, index in keys
    buffer.writeUInt8 key, nextOffset
    buffer.writeUInt8 highValues[key] - lowValues[key], nextOffset + 1
    nextOffset += 2
  callback null, nextOffset - startOffset

parseDictionary = (buffer, startOffset, entryCount, callback) ->
  console.log 'parseDictionary called with dictionary size ' + entryCount

  highValues = {}
  lowValues = {}
  lastSum = 0
  for i in [0...entryCount]
    key = buffer.readUInt8 startOffset + i * 2
    value = buffer.readUInt8 startOffset + i * 2 + 1
    lowValues[key] = lastSum
    lastSum += value
    highValues[key] = lastSum
  callback
    highValues : highValues
    lowValues : lowValues
    scale : lastSum

module.exports =
  createFrequencyMap : createFrequencyMap
  writeDictionary : writeDictionary
  parseDictionary :parseDictionary 
