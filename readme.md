# Arithmetic coding in CoffeeScript
For the compression assignment I decided to use arithmetic coding algorithm. Initially, I was going for Huffman coding, but after doing some research I found that arithmetic coding performs better. It was not as popular as Huffman coding because of its initial patenting issues.

## Compressed file structure
| Segment           | Size          | Note                                      |
|:-----------------:|:-------------:| ------------------------------------------|
| Dictionary size   | 1 bytes       | This is the count of dictionary entries   |
| Output file size  | 4 bytes       | File size of the compressed file. The maximum file size for this format is `2^32` bytes |
| Dictionary        | varying size  | Dictionary can contain at most 256 entries and each entry takes 2 bytes. The dictionary will take at most 512 bytes |
| MD5 digest        | 16 bytes      | MD5 digest of the output file. Used during decompression to verify that the output file was not damaged. |
| Compressed payload| varying size  | The actual compressed data |

## Usage from the command line
In order to run the script, make sure you have `node` and `npm` installed and in your `PATH`. First, run `npm install` in the root of the project to install the package dependencies. After that you can run the script using the `bin/main.js` file. The script accepts the following parameters:
- `[-c, --compress]` - use this to start file compression
- `[-x, --extract]` - use this to start file decompression
- `-f, --inputFile filename` - name of the input file
- `-o, --outputFile filename` - name of the output file
- `[-v, --verbose]` - enable verbose printing of debug info
- `[-h, --help]` - print usage
During the compression, MD5 digest of the original file is inserted into the compressed file. During decompression, the digest is verified, and if it does not match, an error message is shown.


## Algorithm analysis
The complexity of the compression algorithm is O(N) where N is the size of the file in bytes. Decompression takes linear time as well.
In general, the arithmetic encoding is a very efficient algorithm and can be optimized to support mutli-core processors. Even though my implementation is not optimized and uses a scripting language (CoffeeScript), it compresses "War and Piece" text in under 3 seconds.
Arithmetic encoding is flexible and can be used with many frequency models. For example, we can generate the model with LZW and encode it with arithmetic encoding. 

## Calgary test results

| File      | Category                      | Size      | Compressed size   | Time(seconds) |Compression ratio  |
|:---------:|:-----------------------------:|:---------:|:-----------------:|:-------------:|:-----------------:|
| bib       | Bibliography (refer format)   | 111261    | 72571             | 0.459         | 1.53              |
| book1     | Fiction book                  | 768771    | 436766            | 1.430         | 1.76              |
| book2     | Non-fiction book (troff format)| 610856   | 366910            | 1.172         | 1.66              |
| geo       | Geophysical data              | 102400    | 73305             | 0.442         | 1.40              |
| news      | USENET batch file             | 377109    | 245067            | 0.843         | 1.54              |
| obj1      | Object code for VAX           | 21504     | 16639             | 0.327         | 1.29              |
| obj2      | Object code for Apple Mac     | 246814    | 194504            | 0.661         | 1.27              |
| paper1    | Technical paper               | 53161     | 33375             | 0.382         | 1.59              |
| paper2    | Technical paper               | 82199     | 47605             | 0.477         | 1.73              |
| Tolstoy   | Fiction book                  | 3291648   | 1874291           | 5.114         | 1.76              |
