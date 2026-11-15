output=$rgss_compat_output || '.'
red=Bitmap.new(32,32);red.fill_rect(red.rect,Color.new(240,40,20,255))
blue=Bitmap.new(32,32);blue.fill_rect(blue.rect,Color.new(20,180,240,255))
sprites=[]
# Creation order, same-z y ordering, z ordering, then runtime y changes.
[[80,80,80,88,0,0],[180,88,180,80,0,0],[280,80,280,80,0,0],[380,80,380,88,1,0]].each do |ax,ay,bx,by,az,bz|
  a=Sprite.new;a.bitmap=red;a.x=ax;a.y=ay;a.z=az
  b=Sprite.new;b.bitmap=blue;b.x=bx;b.y=by;b.z=bz
  sprites << a << b
end
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
rows=[]
[[84,92],[184,92],[284,84],[384,92]].each {|x,y|c=snapshot.get_pixel(x,y);rows << [x,y,c.red,c.green,c.blue]}
snapshot.dispose
sprites[0].y=96
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
c=snapshot.get_pixel(84,100);rows << ['changed_y',c.red,c.green,c.blue]
File.open(File.join(output,'sprite_sort_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
snapshot.dispose
sprites.each {|sprite|sprite.dispose}
red.dispose;blue.dispose
exit
