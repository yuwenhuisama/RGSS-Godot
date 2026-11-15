output=$rgss_compat_output || '.'
bitmap=Bitmap.new(8,8)
8.times {|y|8.times {|x|bitmap.set_pixel(x,y,Color.new(20+x*25,20+y*25,60,255))}}
viewport=Viewport.new(80,80,24,24);viewport.z=10
plane=Plane.new(viewport);plane.bitmap=bitmap
rows=[]
[0.5,0.75,1.0,1.25,1.5,2.0,3.0].each do |zoom|
  [-5,0,3,8].each do |offset|
    plane.zoom_x=zoom;plane.zoom_y=zoom;plane.ox=offset;plane.oy=offset
    2.times {Graphics.update}
    snap=Graphics.snap_to_bitmap
    pixels=(0...24).map {|n|c=snap.get_pixel(80+n,80+n);[c.red,c.green,c.blue].join(',')}
    rows << [zoom,offset,*pixels];snap.dispose
  end
end
File.open(File.join(output,'plane_sampling_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
plane.dispose;viewport.dispose;bitmap.dispose
exit
