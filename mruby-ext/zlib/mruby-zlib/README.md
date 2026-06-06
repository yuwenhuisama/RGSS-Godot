# mruby-zlib

"mruby-zlib" is a zlib wrapper.

## Example

```Ruby
> deflate = Zlib.deflate("ABC")
 => "x\234str\006\000\001\215\000\307"
> Zlib.inflate(deflate)
 => "ABC"
> gzip = Zlib.gzip("abc")
 => "\037\213\b\000\000\000\000\000\000\003KLJ\006\000\302A$5\003\000\000\000"
> Zlib.inflate(gzip)
 => "abc"
> Zlib.crc32("abc")
 => "5$A\302"  # big endian unsigned 32bit.
               # Sometimes mruby fixnum has not enough size to save crc32.
```


## License

Copyright (c) 2015 Internet Initiative Japan Inc.

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
