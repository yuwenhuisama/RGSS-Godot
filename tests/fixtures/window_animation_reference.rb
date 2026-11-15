output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
skin.fill_rect(0,0,64,128,Color.new(20,40,180,255))
skin.fill_rect(64,0,64,64,Color.new(80,200,20,255))
skin.fill_rect(64,64,32,32,Color.new(240,180,20,255))
[[96,64],[112,64],[96,80],[112,80]].each_with_index {|xy,i|skin.fill_rect(xy[0],xy[1],16,16,Color.new(40+i*50,180-i*30,220-i*40,255))}
contents=Bitmap.new(200,160);contents.fill_rect(contents.rect,Color.new(220,40,100,255))
window=Window.new(80,80,128,96);window.windowskin=skin;window.contents=contents
window.cursor_rect.set(20,20,24,16);window.pause=true;window.arrows_visible=false
rows=[]
[true,false].each do |active|
  window.active=active
  65.times do |step|
    window.update if step>0
    2.times {Graphics.update}
    snap=Graphics.snap_to_bitmap
    points=[[110,110],[140,160]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
    rows << ['tick',active,step,*points];snap.dispose
  end
end
contents.clear
window.dispose
window=Window.new(80,80,128,96);window.windowskin=skin;window.contents=contents
window.cursor_rect.set(20,20,24,16);window.pause=true;window.arrows_visible=false
[true,false].each do |active|
  window.active=active
  65.times do |step|
    window.update if step>0
    2.times {Graphics.update}
    snap=Graphics.snap_to_bitmap
    points=[[110,110],[140,160]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
    rows << ['clear_tick',active,step,*points];snap.dispose
  end
end
contents.fill_rect(contents.rect,Color.new(220,40,100,255))
window.cursor_rect.empty;window.pause=false
[0,1,64,128,192,254,255].each do |openness|
  window.openness=openness
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[80,80],[84,124],[100,100],[100,124],[84,171]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << ['open',openness,*points];snap.dispose
end
window.openness=255
window.cursor_rect.set(20,20,24,16);window.pause=true;contents.clear
[0,128,255].each do |opacity|
  window.opacity=opacity
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[110,110],[140,160]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << ['decoration_opacity',opacity,*points];snap.dispose
end
window.cursor_rect.empty;window.pause=false;contents.fill_rect(contents.rect,Color.new(220,40,100,255))
[0,128,255].each do |opacity|
  window.opacity=opacity;window.contents_opacity=128
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[80,80],[100,100]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << ['opacity',opacity,*points];snap.dispose
end
File.open(File.join(output,'window_animation_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
window.dispose;skin.dispose;contents.dispose;back.dispose;bg.dispose
exit
