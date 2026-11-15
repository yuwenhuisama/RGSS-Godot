output = $rgss_compat_output || '.'
background = Bitmap.new(544,416)
sprite = Sprite.new
sprite.bitmap = background
skin = Bitmap.new(128,128)
32.times do |y|
  32.times do |x|
    edge = [x,y,31-x,31-y].min
    skin.set_pixel(64+x,64+y,Color.new(20+edge*12,40+x*5,60+y*5,32+x*7))
  end
end
window = Window.new(0,0,100,100)
window.windowskin = skin
window.padding = 8
File.open(File.join(output,'cursor_tail_reference.tsv'),'w') do |file|
  [0,255].each do |bg|
    background.fill_rect(background.rect,Color.new(bg,bg,bg))
    (1..9).each do |width|
      [1,3,8,9].each do |height|
        window.cursor_rect.set(8,8,width,height)
        2.times { Graphics.update }
        snapshot = Graphics.snap_to_bitmap
        height.times do |y|
          width.times do |x|
            c = snapshot.get_pixel(16+x,16+y)
            file.puts [bg,width,height,x,y,c.red.to_i,c.green.to_i,c.blue.to_i].join("\t")
          end
        end
        snapshot.dispose
        file.flush
      end
    end
  end
end
window.dispose
skin.dispose
sprite.dispose
background.dispose
exit unless $cursor_tail_host
