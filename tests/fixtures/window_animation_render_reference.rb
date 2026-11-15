output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
skin.fill_rect(0,0,64,128,Color.new(20,40,180,255))
skin.fill_rect(64,0,64,64,Color.new(80,200,20,255))
skin.fill_rect(64,64,32,32,Color.new(240,180,20,255))
[[96,64],[112,64],[96,80],[112,80]].each_with_index {|xy,i|skin.fill_rect(xy[0],xy[1],16,16,Color.new(40+i*50,180-i*30,220-i*40,255))}
window=Window.new(80,80,128,96);window.windowskin=skin;window.cursor_rect.set(20,20,24,16);window.pause=true
File.open(File.join(output,'window_animation_render_reference.rgba'),'wb') do |file|
  41.times do |step|
    window.update if step>0
    2.times {Graphics.update}
    snap=Graphics.snap_to_bitmap
    96.times do |y|
      bytes=[];128.times {|x|c=snap.get_pixel(80+x,80+y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
      file.write(bytes.pack('C*'))
    end
    snap.dispose
  end
end
window.dispose;skin.dispose;back.dispose;bg.dispose
exit
