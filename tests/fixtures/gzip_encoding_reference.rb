output = $rgss_compat_output || '.'
path = File.join(output, 'gzip-encoding.gz')
Zlib::GzipWriter.open(path) { |writer| writer.write("\xe3\x81\x82\xe3\x81\x84") }
File.open(File.join(output, 'gzip_encoding_reference.tsv'), 'w') do |rows|
  [nil, {:external_encoding => 'UTF-8'}, {:external_encoding => 'Windows-31J'}, {:encoding => 'ASCII-8BIT'},
    {:external_encoding => 'utf-8'}, {:external_encoding => 'BINARY'},
    {:external_encoding => 'US-ASCII'}, {:encoding => 'UTF-8:ASCII-8BIT'},
    {:external_encoding => 'UTF-8', :internal_encoding => 'ASCII-8BIT'}].each_with_index do |options, index|
    reader = nil
    begin
      reader = options ? Zlib::GzipReader.open(path, options) : Zlib::GzipReader.open(path)
      rows.puts([index, 'accepted', reader.getc.unpack('H*')[0]].join("\t"))
    rescue StandardError => error
      rows.puts([index, error.class.to_s].join("\t"))
    ensure
      reader.close if reader && !reader.closed?
    end
    rows.flush
  end
end
exit unless $gzip_reference_host
