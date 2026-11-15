output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(32,24);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80
rows=[]
[0,1,2,63,64,127,128,129,192,254,255].each do |opacity|
  sprite.opacity=opacity
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84)
  rows << [opacity,c.red,c.green,c.blue,c.alpha];snap.dispose
end
File.open(File.join(output,'sprite_opacity_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
