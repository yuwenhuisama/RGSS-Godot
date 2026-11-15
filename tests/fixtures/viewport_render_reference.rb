output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(80,64)
bitmap.fill_rect(0,0,40,64,Color.new(160,80,40,255))
bitmap.fill_rect(40,0,40,64,Color.new(20,180,240,255))
viewports=[];sprites=[]
[:clip,:scroll,:color,:tone,:flash,:overlay].each_with_index do |mode,index|
  viewport=Viewport.new(32+(index%3)*176,40+(index/3)*176,128,128)
  viewport.z=index
  sprite=Sprite.new(viewport);sprite.bitmap=bitmap;sprite.x=32;sprite.y=32;sprite.zoom_x=2;sprite.zoom_y=2
  case mode
  when :scroll then viewport.ox=40;viewport.oy=24
  when :color then viewport.color.set(20,200,100,128)
  when :tone then viewport.tone.set(40,-20,60,128)
  when :flash then viewport.flash(Color.new(240,20,100,192),4)
  when :overlay then sprite.opacity=128;viewport.color.set(200,20,100,96)
  end
  viewports << viewport;sprites << sprite
end
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap
File.open(File.join(output,'viewport_render_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[];544.times {|x|c=snap.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snap.dispose;sprites.each {|sprite|sprite.dispose};viewports.each {|viewport|viewport.dispose};bitmap.dispose;back.dispose;bg.dispose
exit
