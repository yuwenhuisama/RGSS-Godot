output = $rgss_compat_output || '.'
path = File.join(output, 'gzip-reader-io.gz')
Zlib::GzipWriter.open(path) { |writer| writer.write("ab\ncd\n") }
File.open(File.join(output, 'gzip_reader_io.tsv'), 'w') do |rows|
  probes = [
    ['partial-buffer', proc { |reader| buffer = 'old'; result = reader.readpartial(2, buffer); [result.equal?(buffer), buffer.unpack('H*')[0], reader.pos].join(',') }],
    ['partial-zero', proc { |reader| buffer = 'old'; result = reader.readpartial(0, buffer); [result.equal?(buffer), buffer.size, reader.pos].join(',') }],
    ['partial-eof', proc { |reader| reader.read; buffer = 'old'; begin; reader.readpartial(2, buffer); rescue EOFError; [buffer.size, reader.pos, reader.eof?].join(','); end }],
    ['read-eof', proc { |reader| reader.read; [reader.read(1).inspect, reader.read.inspect, reader.read(0).inspect].join(',') }],
    ['ungetbyte', proc { |reader| first = reader.getbyte; reader.ungetbyte(90); [first, reader.pos, reader.getbyte, reader.read.unpack('H*')[0]].join(',') }],
    ['ungetc', proc { |reader| reader.getc; reader.ungetc('XY'); [reader.pos, reader.read.unpack('H*')[0]].join(',') }],
    ['lines-enumerator', proc { |reader| values = reader.each_line.to_a; [values.map { |value| value.unpack('H*')[0] }.join(';'), reader.lineno, reader.eof?].join(',') }],
    ['readbyte-eof', proc { |reader| reader.read; reader.readbyte }],
    ['ungetc-before-start', proc { |reader| reader.ungetc('XY'); [reader.pos, reader.getc, reader.pos, reader.getc, reader.pos].join(',') }],
    ['ungetc-three', proc { |reader| reader.getc; reader.ungetc('XYZ'); [reader.pos, reader.read(2), reader.pos].join(',') }],
    ['ungetbyte-before-start', proc { |reader| reader.ungetbyte(90); [reader.pos, reader.getbyte, reader.pos].join(',') }]
  ]
  probes.each do |name, probe|
    reader = nil
    begin
      reader = Zlib::GzipReader.open(path)
      rows.puts [name, probe.call(reader)].join("\t")
    rescue StandardError => error
      rows.puts [name, error.class.to_s].join("\t")
    ensure
      reader.close if reader && !reader.closed?
    end
    rows.flush
  end
end
exit unless $gzip_reference_host
