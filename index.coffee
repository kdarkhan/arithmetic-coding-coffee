init = ->
  ArgumentParser = require 'argparse'
    .ArgumentParser
  compress = require './compress'
  decompress = require './decompress'

  toBoolean = (arg) ->
      !!arg
  parser = new ArgumentParser
    addHelp : true
    description : 'Simple compress/decompress utility'

  parser.addArgument ['-x', '--extract'],
    help : 'Extract compressed file'
    nargs : '?'
    constant : true

  parser.addArgument ['-c', '--compress'],
    help : 'Compress the input file'
    nargs : '?'
    constant : true

  parser.addArgument ['-v', '--verbose'],
    help : 'Print verbose messages'
    nargs : '?'
    constant : true

  parser.addArgument ['-f', '--inputFile'],
    help : 'Input file to the programm'
    required : true

  parser.addArgument ['-o', '--outputFile'],
    help: 'Name of the output file'
    required : true

  args = parser.parseArgs()

  if args.verbose
    process.verbose = true

  if args.extract
    decompress.decompress args.inputFile, args.outputFile
  else if args.compress
    compress.compress args.inputFile, args.outputFile
  else
    console.log 'You need to provide one of the following arguments [-x, --extract, -c, --compress]'
module.exports = ->
  console.log 'compressjs utility called'
  init()
