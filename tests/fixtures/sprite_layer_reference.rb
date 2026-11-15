output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
red=Bitmap.new(32,24);red.fill_rect(red.rect,Color.new(160,80,40,255))
blue=Bitmap.new(32,24);blue.fill_rect(blue.rect,Color.new(20,180,240,255))
a=Sprite.new;a.bitmap=red;a.x=80;a.y=80;a.opacity=128
b=Sprite.new;b.bitmap=blue;b.x=80;b.y=80;b.z=2;b.opacity=128
rows=[]
[0,1,2].each do |blend|
  b.blend_type=blend
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84)
  rows << [blend,c.red,c.green,c.blue,c.alpha];snap.dispose
end
File.open(File.join(output,'sprite_layer_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
a.dispose;b.dispose;red.dispose;blue.dispose;back.dispose;bg.dispose
exit
