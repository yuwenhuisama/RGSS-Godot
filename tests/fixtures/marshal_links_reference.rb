output = $rgss_compat_output || '.'
class MarshalLinkProbe
  attr_reader :value
  def initialize(value)
    @value = value
  end
  def _dump(depth)
    @value
  end
  def self._load(value)
    new(value)
  end
end
shared = ['shared']
cycle = []
cycle << cycle
object = MarshalLinkProbe.new('custom-payload')
payload = [shared, shared, cycle, object, object, "\xe4\xb8\xad\xe6\x96\x87", "\x00\xff\x80"]
loaded = Marshal.load(Marshal.dump(payload))
File.open(File.join(output, 'marshal_links_reference.tsv'), 'w') do |file|
  file.puts ['array-link', loaded[0].equal?(loaded[1])].join("\t")
  file.puts ['cycle-link', loaded[2].equal?(loaded[2][0])].join("\t")
  file.puts ['custom-link', loaded[3].equal?(loaded[4]), loaded[3].value].join("\t")
  file.puts ['utf8-bytes', loaded[5].unpack('H*')[0]].join("\t")
  file.puts ['binary-bytes', loaded[6].unpack('H*')[0]].join("\t")
  File.open(File.join(output, 'marshal_links_payload.bin'), 'wb') { |stream| Marshal.dump(payload, stream) }
  from_file = File.open(File.join(output, 'marshal_links_payload.bin'), 'rb') { |stream| Marshal.load(stream) }
  file.puts ['file-links', from_file[0].equal?(from_file[1]), from_file[2].equal?(from_file[2][0])].join("\t")
  ['x', "\x04\x08[\x06"].each do |bytes|
    begin
      Marshal.load(bytes)
      file.puts ['invalid', bytes.unpack('H*')[0], 'accepted'].join("\t")
    rescue ArgumentError, TypeError => error
      file.puts ['invalid', bytes.unpack('H*')[0], error.class].join("\t")
    end
  end
end
if $marshal_links_peer || $marshal_links_peer_bytes
  peer = $marshal_links_peer_bytes ? Marshal.load($marshal_links_peer_bytes) : File.open($marshal_links_peer, 'rb') { |stream| Marshal.load(stream) }
  File.open(File.join(output, 'marshal_peer_reference.tsv'), 'w') do |file|
    file.puts ['array-link', peer[0].equal?(peer[1])].join("\t")
    file.puts ['cycle-link', peer[2].equal?(peer[2][0])].join("\t")
    file.puts ['custom-link', peer[3].equal?(peer[4]), peer[3].value].join("\t")
    file.puts ['utf8-bytes', peer[5].unpack('H*')[0]].join("\t")
    file.puts ['binary-bytes', peer[6].unpack('H*')[0]].join("\t")
  end
end
exit unless $marshal_links_host
