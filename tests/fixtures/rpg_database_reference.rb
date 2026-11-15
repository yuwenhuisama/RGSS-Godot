output = $rgss_compat_output || '.'
source = $rpg_database_source || 'E:/Projects/RMProject/Data'
canonical = nil
canonical = lambda do |value|
  if value.is_a?(String)
    'S:' + value.unpack('H*')[0]
  elsif value.is_a?(Table)
    'Table:' + value._dump(0).unpack('H*')[0]
  elsif value.is_a?(Color)
    'Color:' + [value.red,value.green,value.blue,value.alpha].join(',')
  elsif value.is_a?(Tone)
    'Tone:' + [value.red,value.green,value.blue,value.gray].join(',')
  elsif value.is_a?(Array)
    '[' + value.map { |entry| canonical.call(entry) }.join(';') + ']'
  elsif value.is_a?(Hash)
    entries = value.keys.map { |key| [canonical.call(key), canonical.call(value[key])] }
    '{' + entries.sort.map { |entry| entry.join('=>') }.join(';') + '}'
  elsif value.is_a?(Numeric) || value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.nil?
    value.inspect
  else
    value.class.to_s + '{' + value.instance_variables.sort.map do |field|
      field.to_s + '=' + canonical.call(value.instance_variable_get(field))
    end.join(';') + '}'
  end
end
files = Dir.glob(source + '/*.rvdata2').sort.reject { |path| File.basename(path) == 'Scripts.rvdata2' }
File.open(File.join(output, 'rpg_database_reference.tsv'), 'w') do |ledger|
  files.each do |path|
    value = File.open(path, 'rb') { |file| Marshal.load(file) }
    name = File.basename(path)
    text = canonical.call(value)
    File.open(File.join(output, name + '.canonical'), 'wb') { |file| file.write(text) }
    ledger.puts [name, value.class, text.size].join("\t")
    ledger.flush
  end
end
exit unless $rpg_database_host
