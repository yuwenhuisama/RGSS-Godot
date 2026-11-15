output=$rgss_compat_output || '.'
bitmap=Bitmap.new(257,1)
257.times {|x|bitmap.set_pixel(x,0,Color.new(x%256,x/256,60,255))}
viewport=Viewport.new(0,0,544,64);viewport.z=10
plane=Plane.new(viewport);plane.bitmap=bitmap
rows=[]
[0.1,0.3,0.7,1.1,1.3,2.3,7.0].each do |zoom|
  plane.zoom_x=zoom;plane.ox=0
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  indices=(0...544).map {|x|c=snap.get_pixel(x,0);c.red.to_i+256*c.green.to_i}
  rows << [zoom,*indices];snap.dispose
end
File.open(File.join(output,'plane_precision_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
plane.dispose;viewport.dispose;bitmap.dispose
exit
