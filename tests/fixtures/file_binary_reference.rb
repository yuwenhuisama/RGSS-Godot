output = $rgss_compat_output || '.'
path = File.join(output, 'file-binary.dat')
File.open(path, 'wb') { |file| file.write([0xc3, 0xa9, 0, 0xff].pack('C*')) }
File.open(File.join(output, 'file_binary.tsv'), 'w') do |rows|
  ['rb', 'r'].each do |mode|
    [nil, 4, 0].each do |length|
      File.open(path, mode) do |file|
        value = length.nil? ? file.read : file.read(length)
        rows.puts [mode, length.nil? ? 'all' : length, value.encoding.name,
          value.size, value.bytesize, value.unpack('H*')[0]].join("\t")
      end
    end
  end
  File.open(path, 'rb') do |file|
    buffer = 'replace'
    value = file.read(4, buffer)
    rows.puts ['outbuf', value.equal?(buffer), value.encoding.name,
      value.size, value.bytesize, value.unpack('H*')[0]].join("\t")
  end
  File.open(path, 'rb') do |file|
    value = file.sysread(4)
    rows.puts ['sysread', value.encoding.name, value.size, value.bytesize,
      value.unpack('H*')[0]].join("\t")
  end
  File.open(path, File::RDONLY | File::BINARY) do |file|
    value = file.read
    rows.puts ['integer-binary', value.encoding.name, value.size, value.bytesize,
      value.unpack('H*')[0]].join("\t")
  end
end
File.delete(path)
exit unless $file_binary_host
