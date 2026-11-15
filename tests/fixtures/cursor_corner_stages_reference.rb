background=Bitmap.new(544,416)
sprite=Sprite.new;sprite.bitmap=background
File.open(TestPaths.output('cursor_corner_stages_reference.tsv'),'w') do |file|
  [0,255].each do |bg|
    background.fill_rect(background.rect,Color.new(bg,bg,bg))
    4.times do |stage|
      skin=Bitmap.new(128,128)
      [[0,0],[28,0],[0,28],[28,28]].each_with_index do |position,index|
        next if index>stage
        4.times do |y|
          4.times do |x|
            sx=position[0]+x;sy=position[1]+y
            skin.set_pixel(64+sx,64+sy,Color.new(20+[sx,sy,31-sx,31-sy].min*12,40+sx*5,60+sy*5,32+sx*7))
          end
        end
      end
      window=Window.new(0,0,64,64);window.windowskin=skin;window.padding=8
      window.cursor_rect.set(8,8,3,3)
      2.times {Graphics.update}
      bitmap=Graphics.snap_to_bitmap
      3.times do |y|
        3.times do |x|
          c=bitmap.get_pixel(16+x,16+y)
          file.puts([bg,stage,x,y,c.red.to_i,c.green.to_i,c.blue.to_i].join("\t"))
        end
      end
      bitmap.dispose;window.dispose;skin.dispose
    end
  end
end
sprite.dispose;background.dispose
exit
