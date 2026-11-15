output = $rgss_compat_output || '.'
class MarshalStateProbe
  attr_reader :value
  def initialize(value)
    @value = value
  end
  def marshal_dump
    [@value]
  end
  def marshal_load(values)
    @value = values[0]
  end
end
MarshalValueStruct = Struct.new(:value, :link)
File.open(File.join(output,'marshal_values_reference.tsv'),'w') do |file|
  [0,1,-1,2147483647,2147483648,-2147483649,1099511627776,9223372036854775807,-9223372036854775808].each do |number|
    restored = Marshal.load(Marshal.dump(number))
    raise "integer type changed: #{number} -> #{restored.class}" unless restored.is_a?(Integer)
    file.puts ['integer',number,restored,number == restored].join("\t")
  end
  [0.0,-0.0,1.25,1.0/0.0,-1.0/0.0].each do |number|
    restored = Marshal.load(Marshal.dump(number))
    file.puts ['float',number.to_s,restored.to_s].join("\t")
  end
  hash = Hash.new(7)
  hash[:present] = 2
  restored = Marshal.load(Marshal.dump(hash))
  file.puts ['hash-default',restored[:present],restored[:missing],restored.default].join("\t")
  object = MarshalStateProbe.new(42)
  restored = Marshal.load(Marshal.dump([object,object]))
  file.puts ['marshal-load',restored[0].value,restored[0].equal?(restored[1])].join("\t")
  payload = [1099511627776,1099511627776,'tail','tail']
  restored = Marshal.load(Marshal.dump(payload))
  file.puts ['bignum-links',restored == payload].join("\t")
  huge = 2 ** 100
  file.puts ['bigint',Marshal.load(Marshal.dump(huge)) == huge,Marshal.load(Marshal.dump(-huge)) == -huge].join("\t")
  structure = MarshalValueStruct.new(42,nil)
  structure.link = structure
  restored = Marshal.load(Marshal.dump(structure))
  file.puts ['struct-cycle',restored.value,restored.equal?(restored.link)].join("\t")
  linked_hash = Hash.new(['default'])
  linked_hash[:self] = linked_hash
  linked_hash[:default] = linked_hash.default
  restored = Marshal.load(Marshal.dump(linked_hash))
  file.puts ['hash-cycle-default',restored.equal?(restored[:self]),restored.default.equal?(restored[:default])].join("\t")
  File.open(File.join(output,'marshal_values_payload.bin'),'wb') { |stream| Marshal.dump(payload,stream) }
  if $marshal_values_peer || $marshal_values_peer_bytes
    peer = $marshal_values_peer_bytes ? Marshal.load($marshal_values_peer_bytes) : File.open($marshal_values_peer,'rb') { |stream| Marshal.load(stream) }
    raise 'peer bignum payload mismatch' unless peer == payload
  end
  file.flush
end
exit unless $marshal_values_host
