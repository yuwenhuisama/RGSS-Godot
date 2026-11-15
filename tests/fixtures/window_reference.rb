output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(20,150,40,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
skin.fill_rect(0,0,64,64,Color.new(20,40,180,255))
skin.fill_rect(0,64,64,64,Color.new(220,40,100,128))
skin.fill_rect(64,0,64,64,Color.new(80,200,20,255))
contents=Bitmap.new(200,160)
contents.fill_rect(0,0,100,160,Color.new(240,180,20,255))
contents.fill_rect(100,0,100,160,Color.new(40,220,220,255))
window=Window.new(80,80,128,96);window.windowskin=skin;window.contents=contents
window.active=false;window.arrows_visible=false
rows=[]
[:background,:full,:scroll,:padding,:tone,:no_skin,:small].each do |mode|
  window.windowskin=skin;window.contents=contents;window.contents_opacity=255
  window.ox=0;window.oy=0;window.padding=12;window.padding_bottom=12
  window.width=128;window.height=96;window.tone.set(0,0,0,0)
  case mode
  when :background then window.contents_opacity=0
  when :scroll then window.ox=96;window.oy=40
  when :padding then window.padding=20;window.padding_bottom=28
  when :tone then window.tone.set(40,-20,60,128);window.contents_opacity=0
  when :no_skin then window.windowskin=nil
  when :small then window.width=20;window.height=16
  end
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[80,80],[81,81],[90,90],[92,92],[100,100],[110,110],[190,150],[195,155],[196,156],[207,175],[208,176],[210,110]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [mode,*points];snap.dispose
end
File.open(File.join(output,'window_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
window.dispose;skin.dispose;contents.dispose;back.dispose;bg.dispose
exit
