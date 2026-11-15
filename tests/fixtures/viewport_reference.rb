output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(80,80);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
viewport=Viewport.new(80,80,48,48)
viewport.z=300
sprite=Sprite.new(viewport);sprite.bitmap=bitmap;sprite.x=8;sprite.y=8
rows=[]
[:plain,:scroll,:move,:color,:tone,:flash,:hide,:empty].each do |mode|
  viewport.ox=0;viewport.oy=0;viewport.rect.set(80,80,48,48)
  viewport.color.set(0,0,0,0);viewport.tone.set(0,0,0,0)
  case mode
  when :scroll then viewport.ox=16;viewport.oy=16
  when :move then viewport.rect.x=100
  when :color then viewport.color.set(20,200,100,128)
  when :tone then viewport.tone.set(40,-20,60,128)
  when :flash then viewport.flash(Color.new(240,20,100,192),4)
  when :hide then viewport.flash(nil,4)
  when :empty then viewport.update;viewport.rect.width=0
  end
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[80,80],[88,88],[120,120],[128,128],[108,88]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [mode,*points];snap.dispose
end
File.open(File.join(output,'viewport_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;viewport.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
