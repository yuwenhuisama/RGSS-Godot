output = $rgss_compat_output || '.'
path = File.join(output, 'gzip-reference.gz')
File.open(File.join(output, 'gzip_reference.tsv'), 'w') do |file|
  writer = Zlib::GzipWriter.open(path)
  writer.mtime = 946684800
  writer.orig_name = 'fixture.txt'
  writer.comment = 'compatibility'
  file.puts ['write', writer.write("first\nsecond\n"), writer.pos].join("\t")
  writer.close
  file.puts ['writer-closed', writer.closed?].join("\t")
  reader = Zlib::GzipReader.open(path)
  file.puts ['metadata', reader.orig_name, reader.comment, reader.mtime.to_i].join("\t")
  file.puts ['line', reader.gets.inspect, reader.lineno, reader.pos].join("\t")
  file.puts ['rest', reader.read.inspect, reader.eof?].join("\t")
  reader.rewind
  file.puts ['rewind', reader.pos, reader.read.inspect].join("\t")
  reader.close
  file.puts ['reader-closed', reader.closed?].join("\t")
  File.open(path, 'wb') { |stream| stream.write('broken') }
  begin
    Zlib::GzipReader.open(path)
    file.puts ['corrupt', 'accepted'].join("\t")
  rescue StandardError => error
    file.puts ['corrupt', error.class].join("\t")
  end
  file.flush
end
exit unless $gzip_reference_host
