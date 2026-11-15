output = $rgss_compat_output || '.'
begin
  object = [1, 'text', { 'nested' => [2, 3] }]
  encoded = Marshal.dump(object)
  File.open(File.join(output, 'marshal_io_reference.tsv'), 'w') do |rows|
    File.open(File.join(output, 'marshal_io_payload.bin'), 'wb') do |file|
      returned = Marshal.dump(object, file)
      rows.puts(['io-return', returned.equal?(file)].join("\t"))
    end
    File.open(File.join(output, 'marshal_io_payload.bin'), 'rb') do |file|
      rows.puts(['io-roundtrip', Marshal.load(file) == object].join("\t"))
    end
    rows.puts(['io-bytes', File.open(File.join(output, 'marshal_io_payload.bin'), 'rb') { |file| file.read } == encoded].join("\t"))
    begin
      Marshal.dump(object, nil)
      rows.puts(['nil-io', 'accepted'].join("\t"))
    rescue TypeError
      rows.puts(['nil-io', 'TypeError'].join("\t"))
    end
    rows.puts(['depth-positional', Marshal.dump(object, 20) == encoded].join("\t"))
    File.open(File.join(output, 'marshal_io_payload.bin'), 'wb') do |file|
      rows.puts(['depth-third', Marshal.dump(object, file, 20).equal?(file)].join("\t"))
    end
    begin
      Marshal.dump(object, 0)
      rows.puts(['depth-limit', 'did-not-raise'].join("\t"))
    rescue ArgumentError
      rows.puts(['depth-limit', 'ArgumentError'].join("\t"))
    end
  end
rescue Exception => error
  File.open(File.join(output, 'marshal_io_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
end
exit unless $rgss_compat_output
