output = $rgss_compat_output || '.'
bitmap = Bitmap.new(180, 140)
File.open(File.join(output, 'bitmap_text_fractional_reference.tsv'), 'w') do |file|
  [[1.8, 2.8, 112, 24], [0, 57.6, 112, 24], [-1.8, 2.8, 112.8, 24.8]].each do |rect|
    begin
      bitmap.draw_text(*rect, 'Actor')
      file.puts (rect + ['accepted']).join("\t")
    rescue Exception => error
      file.puts (rect + [error.class.to_s]).join("\t")
    end
  end
  [[1.8, 2.8], [0, 57.6], [-1.8, 2.8]].each do |position|
    begin
      bitmap.blt(*position, bitmap, Rect.new(0,0,2,2))
      file.puts (['blt'] + position + ['accepted']).join("\t")
    rescue Exception => error
      file.puts (['blt'] + position + [error.class.to_s]).join("\t")
    end
  end
end
bitmap.dispose
exit unless $fractional_text_host
