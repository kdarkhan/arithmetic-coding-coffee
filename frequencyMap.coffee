
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
  keyArray.sort (a, b) ->
    a - b
  valueArray = keyArray.map (key) ->
    newMap[key]
  keys: keyArray
  values: valueArray

createFrequencyMap = (dataBuffer, callback) ->
  console.log 'createFrequencyMap() called'
  freqMap = []
  largest = 0
  for index in [0 ... dataBuffer.length]
    byte = dataBuffer.readUInt8 index
    if freqMap[byte]
      freqMap[byte] += 1
    else
      freqMap[byte] = 1
    if largest < freqMap[byte]
      largest = freqMap[byte]
  callback null, scaleFrequencyMap freqMap, largest

module.exports =
  createFrequencyMap : createFrequencyMap