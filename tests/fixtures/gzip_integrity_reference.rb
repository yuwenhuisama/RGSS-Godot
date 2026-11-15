output = $rgss_compat_output || '.'
path = File.join(output, 'gzip-integrity.gz')
Zlib::GzipWriter.open(path) { |writer| writer.write('integrity payload') }
source = File.open(path, 'rb') { |file| file.read }
File.open(File.join(output, 'gzip_integrity.tsv'), 'w') do |rows|
  ['crc', 'length', 'no-footer', 'short-body', 'trailing', 'early-close'].each do |name|
    selector = File.join(output, 'gzip_integrity_case.txt')
    next if File.exist?(selector) && File.read(selector).strip != name
    progress = File.join(output, 'gzip_integrity_progress.txt')
    File.open(progress, 'w') { |file| file.puts [name, 'prepare'].join("\t") }
    bytes = source.dup
    case name
    when 'crc' then bytes.setbyte(bytes.size - 8, bytes.getbyte(bytes.size - 8) ^ 1)
    when 'length' then bytes.setbyte(bytes.size - 4, bytes.getbyte(bytes.size - 4) ^ 1)
    when 'no-footer' then bytes = bytes[0, bytes.size - 8]
    when 'short-body' then bytes = bytes[0, 12]
    when 'trailing' then bytes += 'TAIL'
    end
    File.open(path, 'wb') { |file| file.write(bytes) }
    reader = nil
    stage = 'open'
    begin
      reader = Zlib::GzipReader.open(path)
      stage = 'read'
      File.open(progress, 'w') { |file| file.puts [name, stage].join("\t") }
      if name == 'early-close'
        value = reader.read(1)
      else
        value = reader.read
      end
      stage = 'close'
      File.open(progress, 'w') { |file| file.puts [name, 'unused-or-close'].join("\t") }
      unused = '-'
      if name == 'trailing'
        begin
          unused = reader.unused.inspect
        rescue NotImplementedError => error
          unused = error.class.to_s
        end
        File.open(File.join(output, 'gzip_unused_diagnostic.txt'), 'w') { |file| file.puts unused }
        unused = '-'
      end
      reader.close
      rows.puts [name, 'accepted', value.unpack('H*')[0], unused].join("\t")
    rescue StandardError => error
      rows.puts [name, stage, error.class.to_s].join("\t")
    rescue Exception => error
      File.open(File.join(output, 'gzip_integrity_fatal.txt'), 'w') do |file|
        file.puts [name, stage, error.class.to_s, error.message, *error.backtrace].join("\n")
      end
      raise
    ensure
      rows.flush
      File.open(progress, 'w') { |file| file.puts [name, 'cleanup'].join("\t") }
      begin
        reader.close if reader && !reader.closed?
      rescue StandardError
        # The primary row already records the operation that rejected this stream.
      end
      File.open(progress, 'w') { |file| file.puts [name, 'done'].join("\t") }
    end
    rows.flush
  end
end
exit unless $gzip_reference_host
