output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
red=Bitmap.new(32,32);red.fill_rect(red.rect,Color.new(160,80,40,255))
blue=Bitmap.new(32,32);blue.fill_rect(blue.rect,Color.new(20,180,240,255))
viewport=Viewport.new(80,80,64,64)
sprite=Sprite.new(viewport);sprite.bitmap=red
nil_sprite=Sprite.new;nil_sprite.bitmap=blue;nil_sprite.x=80;nil_sprite.y=80
rows=[]
[[-1,0],[0,-1],[0,1],[1,0],[200,100],[100,200]].each do |vz,sz|
  viewport.z=vz;nil_sprite.z=sz
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84)
  rows << [vz,sz,c.red,c.green,c.blue,c.alpha];snap.dispose
end
File.open(File.join(output,'viewport_sort_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;nil_sprite.dispose;viewport.dispose;red.dispose;blue.dispose;back.dispose;background.dispose
exit
