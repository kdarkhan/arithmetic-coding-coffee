crypto = require 'crypto'

logger = if process.verbose then console.log else ->

md5digest = (readBuffer, writeBuffer, startOffset, callback) ->
  hash = crypto.createHash 'md5'
  hash.update readBuffer
  hashBuffer = hash.digest()
  hashBuffer.copy writeBuffer, startOffset
  logger 'digest result was written'
  logger 'digest result is ' + hashBuffer
  logger 'digest result is ' + hashBuffer.length
  callback null


md5verify = (buffer, digest, callback) ->
  hash = crypto.createHash 'md5'
  hash.update buffer
  digestBuffer = hash.digest()
  console.log 'resulting digest is ' + digestBuffer.toString 'hex'
  if digestBuffer.equals digest
    console.log 'digest matches the expected value'
  else
    console.log 'Error: digest does not match expected value'


module.exports =
  md5digest: md5digest
  md5verify: md5verify