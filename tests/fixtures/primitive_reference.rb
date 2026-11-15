# Shared original RGSS3 and Godot fixture. Results are public API observations.
output = $rgss_compat_output || '.'
rows = []
rows << ['font_default', Font.default_name.inspect, Font.default_size]
['Arial', 'VL Gothic', 'CompatibilityMissingFont'].each { |name| rows << ['font_exists', name, Font.exist?(name)] }
bitmap = Bitmap.new(64, 48)
rows << ['bitmap_dimensions', bitmap.width, bitmap.height, bitmap.rect.width, bitmap.rect.height]
bitmap.fill_rect(0, 0, 64, 48, Color.new(20, 40, 60, 255))
pixel = bitmap.get_pixel(12, 12)
rows << ['bitmap_pixel', pixel.red, pixel.green, pixel.blue, pixel.alpha]
['Arial', 'VL Gothic'].each do |name|
  bitmap.font.name = name
  rows << ['font_name_after_string', name, bitmap.font.name.inspect]
  ['Hello', 'iiii', 'WWWW', '12345', '', 'H', 'e', 'l', 'o', 'i', 'W', '1', 'A', 'V', 'AV', ' ', '2', '3', '4', '5', 'I', 't', 'a', 'c', 'S', 'h', 'd', 'w', 'O', 'u', 'n', 'Hello AV iiii WWWW 12345'].each do |text|
    rect = bitmap.text_size(text)
    rows << ['text_size', name, text, rect.width, rect.height]
  end
end
bitmap.font.name = ['CompatibilityMissingFont', 'Arial']
rows << ['font_name_after_array', bitmap.font.name.inspect]
rows << ['font_array_measure', bitmap.text_size('Hello').width]
table = Table.new(2, 2, 2)
table[1, 1, 1] = -321
rows << ['table_roundtrip', Marshal.load(Marshal.dump(table))[1, 1, 1]]
bitmap.dispose
File.open(File.join(output, 'primitive_reference.tsv'), 'w') do |file|
  rows.each { |row| file.puts(row.join("\t")) }
end
exit
