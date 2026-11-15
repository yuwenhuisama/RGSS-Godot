output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(8,8)
bitmap.fill_rect(0,0,4,4,Color.new(160,80,40,255))
bitmap.fill_rect(4,0,4,4,Color.new(20,180,240,255))
bitmap.fill_rect(0,4,4,4,Color.new(220,40,100,255))
bitmap.fill_rect(4,4,4,4,Color.new(80,200,20,255))
viewports=[];planes=[]
[:plain,:scroll,:zoom,:color,:tone,:opacity].each_with_index do |mode,index|
  viewport=Viewport.new(32+(index%3)*176,40+(index/3)*176,128,128);viewport.z=index
  plane=Plane.new(viewport);plane.bitmap=bitmap
  case mode
  when :scroll then plane.ox=3;plane.oy=5;viewport.ox=5;viewport.oy=3
  when :zoom then plane.zoom_x=1.5;plane.zoom_y=0.75;plane.ox=5;plane.oy=3
  when :color then plane.color.set(20,200,100,128)
  when :tone then plane.tone.set(40,-20,60,128)
  when :opacity then plane.opacity=128
  end
  viewports << viewport;planes << plane
end
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap
File.open(File.join(output,'plane_render_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[];544.times {|x|c=snap.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snap.dispose;planes.each {|plane|plane.dispose};viewports.each {|viewport|viewport.dispose};bitmap.dispose;back.dispose;bg.dispose
exit
