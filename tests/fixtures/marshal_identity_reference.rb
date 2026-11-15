output = $rgss_compat_output || '.'
payload = [0.0, 0, 1.0, 1, -1.0, -1]
restored = Marshal.load(Marshal.dump(payload))
a = 'same'
b = 'same'
strings = Marshal.load(Marshal.dump([a, b, a]))
File.open(File.join(output, 'marshal_identity_reference.tsv'), 'w') do |file|
  file.puts ['mixed-types', restored.map { |value| value.class.to_s }.join(',')].join("\t")
  file.puts ['distinct-strings', strings[0].equal?(strings[1])].join("\t")
  file.puts ['shared-string', strings[0].equal?(strings[2])].join("\t")
end
raise 'numeric types changed' unless restored.map { |value| value.class } == payload.map { |value| value.class }
raise 'distinct strings merged' if strings[0].equal?(strings[1])
raise 'shared string lost' unless strings[0].equal?(strings[2])
exit unless $marshal_identity_host
