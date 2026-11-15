output = $rgss_compat_output || '.'
path = File.join(output, 'gzip-encoding-extended.gz')
Zlib::GzipWriter.open(path) { |writer| writer.write("\xe3\x81\x82\xe3\x81\x84") }
File.open(File.join(output, 'gzip_encoding_extended.tsv'), 'w') do |rows|
  [
    ['utf16le', {:external_encoding => 'UTF-16LE'}],
    ['latin1', {:external_encoding => 'ISO-8859-1'}],
    ['eucjp', {:external_encoding => 'EUC-JP'}],
    ['shiftjis', {:external_encoding => 'Shift_JIS'}],
    ['utf8-internal-utf8', {:external_encoding => 'UTF-8', :internal_encoding => 'UTF-8'}],
    ['utf8-internal-ascii', {:external_encoding => 'UTF-8', :internal_encoding => 'US-ASCII'}],
    ['internal-only', {:internal_encoding => 'ASCII-8BIT'}],
    ['unknown-internal', {:external_encoding => 'UTF-8', :internal_encoding => 'not-an-encoding'}],
    ['nil-external', {:external_encoding => nil}],
    ['empty-external', {:external_encoding => ''}]
  ].each do |name, options|
    reader = nil
    begin
      reader = Zlib::GzipReader.open(path, options)
      rows.puts [name, 'accepted', reader.getc.unpack('H*')[0]].join("\t")
    rescue StandardError => error
      rows.puts [name, error.class.to_s].join("\t")
    ensure
      reader.close if reader && !reader.closed?
    end
    rows.flush
  end
  [
    ['utf16le-pair', "\x3d\xd8\x00\xdeA\x00"],
    ['utf16le-short', "\x41"],
    ['utf16le-high', "\x3d\xd8A\x00"],
    ['utf16le-low', "\x00\xdeA\x00"]
  ].each do |name, payload|
    Zlib::GzipWriter.open(path) { |writer| writer.write(payload) }
    reader = nil
    begin
      reader = Zlib::GzipReader.open(path, {:external_encoding => 'UTF-16LE'})
      values = []
      while (character = reader.getc)
        values << character.unpack('H*')[0]
      end
      rows.puts [name, 'accepted', values.join(',')].join("\t")
    rescue StandardError => error
      rows.puts [name, error.class.to_s].join("\t")
    ensure
      reader.close if reader && !reader.closed?
    end
    rows.flush
  end
end
exit unless $gzip_reference_host
