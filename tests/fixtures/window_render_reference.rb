output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(20,150,40,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
skin.fill_rect(0,0,64,64,Color.new(20,40,180,255))
skin.fill_rect(0,64,32,64,Color.new(220,40,100,128))
skin.fill_rect(32,64,32,64,Color.new(80,180,220,128))
skin.fill_rect(64,0,64,64,Color.new(80,200,20,255))
contents=Bitmap.new(200,160)
contents.fill_rect(0,0,100,80,Color.new(240,180,20,255))
contents.fill_rect(100,0,100,80,Color.new(40,220,220,255))
contents.fill_rect(0,80,200,80,Color.new(200,80,200,255))
windows=[]
values=[]
[:background,:contents,:scroll,:padding,:tone,:small].each_with_index do |mode,index|
  window=Window.new(32+(index%3)*176,40+(index/3)*176,128,96)
  window.windowskin=skin;window.contents=contents;window.active=false;window.arrows_visible=false
  values << [mode,window.padding,window.padding_bottom]
  case mode
  when :background then window.contents_opacity=0
  when :scroll then window.ox=96;window.oy=72
  when :padding then window.padding=20;window.padding_bottom=28
  when :tone then window.tone.set(40,-20,60,128);window.contents_opacity=0
  when :small then window.width=20;window.height=16
  end
  windows << window
end
File.open(File.join(output,'window_default_reference.tsv'),'w') {|file|values.each {|row|file.puts(row.join("\t"))}}
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap
File.open(File.join(output,'window_render_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[];544.times {|x|c=snap.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snap.dispose;windows.each {|window|window.dispose};skin.dispose;contents.dispose;back.dispose;bg.dispose
exit
