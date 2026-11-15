output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
red=Bitmap.new(64,64);red.fill_rect(red.rect,Color.new(160,80,40,255))
blue=Bitmap.new(64,64);blue.fill_rect(blue.rect,Color.new(20,180,240,255))
first=Viewport.new(80,80,48,48);first.z=5;first.color.set(20,200,100,128)
a=Sprite.new(first);a.bitmap=red;a.opacity=128
second=Viewport.new(96,96,48,48);second.z=10;second.tone.set(40,-20,60,128)
b=Sprite.new(second);b.bitmap=blue;b.opacity=128;b.blend_type=2
top=Sprite.new;top.bitmap=blue;top.x=112;top.y=112;top.z=20
rows=[]
[false,true].each do |swap|
  first.z=swap ? 15 : 5
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[84,84],[100,100],[132,100],[116,116],[76,76],[144,144]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [swap,*points];snap.dispose
end
File.open(File.join(output,'viewport_overlap_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
top.dispose;a.dispose;b.dispose;first.dispose;second.dispose;red.dispose;blue.dispose;back.dispose;bg.dispose
exit
