output=$rgss_compat_output || '.'
background=Bitmap.new(544,416)
background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
bitmap=Bitmap.new(32,24)
bitmap.fill_rect(0,0,16,24,Color.new(240,40,20,255))
bitmap.fill_rect(16,0,16,24,Color.new(20,180,240,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80
rows=[]
[[16,0,16,24],[0,0,0,24],[-8,0,24,24],[24,0,24,24]].each_with_index do |rect,index|
  sprite.src_rect.set(*rect)
  8.times {Graphics.update}
  snapshot=Graphics.snap_to_bitmap
  points=[[80,80],[88,80],[96,80],[104,80]].map {|x,y|c=snapshot.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [index,sprite.width,sprite.height,*points]
  snapshot.dispose
end
File.open(File.join(output,'sprite_region_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose
back.dispose;background.dispose
exit
