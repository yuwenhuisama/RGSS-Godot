output = $rgss_compat_output || '.'
File.open(File.join(output, 'font_short_layout_reference.tsv'), 'w') do |file|
  [false, true].each do |outline|
    [8, 23, 24, 25, 40].each do |height|
      [0, 1, 2].each do |align|
        ['A', '123', ': 1'].each do |text|
          bitmap = Bitmap.new(160,64)
          bitmap.font.name = 'Arial'
          bitmap.font.size = 24
          bitmap.font.outline = outline
          bitmap.font.shadow = false
          bitmap.draw_text(8,8,128,height,text,align)
          pixels = []
          64.times do |y|
            160.times { |x| pixels << [x,y] if bitmap.get_pixel(x,y).alpha > 32 }
          end
          bounds = pixels.empty? ? [-1,-1,-1,-1] :
            [pixels.map { |p| p[0] }.min, pixels.map { |p| p[1] }.min,
             pixels.map { |p| p[0] }.max, pixels.map { |p| p[1] }.max]
          measured = bitmap.text_size(text)
          file.puts([outline,height,align,text,measured.width,measured.height,*bounds].join("\t"))
          bitmap.dispose
        end
      end
    end
  end
end
exit
