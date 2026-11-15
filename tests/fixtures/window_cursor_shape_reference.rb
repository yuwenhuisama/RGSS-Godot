output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,$cursor_white_probe ? Color.new(255,255,255) : Color.new(0,0,0))
sprite=Sprite.new;sprite.bitmap=background
skin=Bitmap.new(128,128)
32.times do |y|
  32.times do |x|
    edge=[x,y,31-x,31-y].min
    skin.set_pixel(64+x,64+y,Color.new(20+edge*12,40+x*5,60+y*5,$cursor_alpha_probe ? 32+x*7 : 255))
  end
end
window=Window.new(0,0,240,180);window.windowskin=skin;window.padding=8
File.open(File.join(output,$cursor_white_probe ? 'window_cursor_alpha_white_reference.tsv' : $cursor_alpha_probe ? 'window_cursor_alpha_reference.tsv' : 'window_cursor_shape_reference.tsv'),'w') do |file|
  [[96,24],[24,48],[8,8],[3,3]].each do |width,height|
    window.cursor_rect.set(8,8,width,height)
    2.times {Graphics.update}
    snapshot=Graphics.snap_to_bitmap
    height.times do |y|
      width.times do |x|
        c=snapshot.get_pixel(16+x,16+y)
        file.puts([width,height,x,y,c.red.to_i,c.green.to_i,c.blue.to_i].join("\t"))
      end
    end
    snapshot.dispose
  end
end
window.dispose;skin.dispose;sprite.dispose;background.dispose
exit
