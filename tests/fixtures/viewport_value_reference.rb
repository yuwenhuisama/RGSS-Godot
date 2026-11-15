output=$rgss_compat_output || '.'
rows=[]
[[0,0],[-1,12],[12,-1],[0,12],[12,0]].each do |width,height|
  viewport=Viewport.new(0,0,width,height)
  rows << [width,height,viewport.rect.width,viewport.rect.height]
  viewport.dispose
end
a=Viewport.new(80,80,32,32);b=Viewport.new(80,80,32,32)
red=Bitmap.new(32,32);red.fill_rect(red.rect,Color.new(160,80,40,255))
blue=Bitmap.new(32,32);blue.fill_rect(blue.rect,Color.new(20,180,240,255))
sa=Sprite.new(a);sa.bitmap=red
sb=Sprite.new(b);sb.bitmap=blue
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84);rows << ['tie',c.red,c.green,c.blue];snap.dispose
sb.viewport=a;sa.z=2
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84);rows << ['reassign',c.red,c.green,c.blue];snap.dispose
File.open(File.join(output,'viewport_value_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sa.dispose;sb.dispose;a.dispose;b.dispose;red.dispose;blue.dispose
exit
