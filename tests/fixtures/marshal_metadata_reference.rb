output = $rgss_compat_output || '.'
key = :shared_symbol
hash = {key => [1,2]}
payload = [key,key,hash,hash]
loaded = Marshal.load(Marshal.dump(payload))
File.open(File.join(output,'marshal_metadata_reference.tsv'),'w') do |file|
  file.puts ['symbol-link',loaded[0].equal?(loaded[1])].join("\t")
  file.puts ['hash-link',loaded[2].equal?(loaded[3])].join("\t")
  file.puts ['hash-symbol-key',loaded[2][loaded[0]].join(',')].join("\t")
  ['UTF-8','ASCII-8BIT','US-ASCII','Windows-31J'].each do |encoding|
    bytes = encoding == 'Windows-31J' ? "\x82\xa0" : encoding == 'US-ASCII' ? 'abc' : "\xe4\xb8\xad"
    begin
      string = bytes.force_encoding(encoding)
      restored = Marshal.load(Marshal.dump(string))
      File.open(File.join(output, 'encoding-' + encoding + '.bin'), 'wb') { |stream| Marshal.dump(string, stream) }
      file.puts ['encoding',encoding,restored.encoding.name,restored.unpack('H*')[0]].join("\t")
      copied = string.dup
      file.puts ['encoding-copy',encoding,copied.encoding.name,copied.unpack('H*')[0]].join("\t")
    rescue NoMethodError, ArgumentError => error
      puts ['ENCODING_ERROR',encoding,error.message].join(':') if $marshal_metadata_host
      file.puts ['encoding',encoding,error.class].join("\t")
    end
    file.flush
  end
end
File.open(File.join(output, 'marshal_frozen_encoding.tsv'), 'w') do |file|
  plain = 'abc'.freeze
  file.puts ['frozen-query', plain.encoding.name].join("\t")
  begin
    plain.force_encoding('ASCII-8BIT')
    file.puts ['frozen-change', 'accepted'].join("\t")
  rescue RuntimeError => error
    file.puts ['frozen-change', error.class.to_s].join("\t")
  end
  binary = 'abc'.force_encoding('ASCII-8BIT').freeze
  file.puts ['frozen-roundtrip', Marshal.load(Marshal.dump(binary)).encoding.name].join("\t")
end
if $marshal_encoding_peer
  File.open(File.join(output, 'marshal_encoding_peer.tsv'), 'w') do |file|
    ['UTF-8','ASCII-8BIT','US-ASCII'].each do |encoding|
      restored = File.open(File.join($marshal_encoding_peer, 'encoding-' + encoding + '.bin'), 'rb') { |stream| Marshal.load(stream) }
      file.puts [encoding,restored.encoding.name,restored.unpack('H*')[0]].join("\t")
    end
  end
end
exit unless $marshal_metadata_host
