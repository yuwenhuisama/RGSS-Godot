output = $rgss_compat_output || '.'
bitmap = Bitmap.new(544, 416)
bitmap.fill_rect(0,0,544,416,Color.new(64,64,64,255))
bitmap.font.name = 'Arial'
bitmap.font.size = 24
bitmap.font.outline = false
bitmap.font.shadow = false
measurements = []
measurements << ['font_name', bitmap.font.name.inspect, bitmap.font.size]
['Hello AV iiii WWWW 12345', 'Hello World', 'Italic Hello AV', 'Shadow Hello AV', 'Outline Hello AV'].each do |text|
  rect = bitmap.text_size(text)
  measurements << [text, rect.width, rect.height]
end
File.open(File.join(output, 'text_render_metrics.tsv'), 'w') { |f| measurements.each { |row| f.puts(row.join("\t")) } }
bitmap.draw_text(20, 20, 250, 40, 'Hello AV iiii WWWW 12345')
bitmap.draw_text(20, 80, 60, 40, 'Hello World')
bitmap.font.bold = true
bitmap.draw_text(20, 140, 300, 40, 'Bold Hello AV')
bitmap.font.bold = false
bitmap.font.italic = true
bitmap.draw_text(20, 200, 300, 40, 'Italic Hello AV')
bitmap.font.italic = false
bitmap.font.shadow = true
bitmap.draw_text(20, 260, 300, 40, 'Shadow Hello AV')
bitmap.font.outline = true
bitmap.draw_text(20, 320, 300, 40, 'Outline Hello AV')
sprite = Sprite.new
sprite.bitmap = bitmap
8.times { Graphics.update }
snapshot = Graphics.snap_to_bitmap
File.open(File.join(output, 'text_ink_bounds.tsv'), 'w') do |file|
  [[20,60],[80,120],[140,180],[200,240],[260,300],[320,360]].each do |range|
    pixels = []
    (range[0]...range[1]).each do |y|
      (0...544).each do |x|
        c = snapshot.get_pixel(x,y)
        pixels << [x,y] if c.red > 180 && c.green > 180 && c.blue > 180
      end
    end
    file.puts([range[0], pixels.map{|p|p[0]}.min, pixels.map{|p|p[0]}.max, pixels.map{|p|p[1]}.min, pixels.map{|p|p[1]}.max].join("\t"))
  end
end
File.open(File.join(output, 'text_render_reference.rgba'), 'wb') do |file|
  snapshot.height.times do |y|
    row = []
    snapshot.width.times do |x|
      c = snapshot.get_pixel(x,y)
      row.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])
    end
    file.write(row.pack('C*'))
  end
end
snapshot.dispose
sprite.dispose
bitmap.dispose
exit
