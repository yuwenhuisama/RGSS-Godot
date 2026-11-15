output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(8,8);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
viewport=Viewport.new(80,80,24,24)
plane=Plane.new(viewport);plane.bitmap=bitmap;plane.zoom_x=0.01
File.open(File.join(output,'plane_mode_progress.txt'),'w') {|file|file.puts('tiny_zoom')}
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(80,80)
File.open(File.join(output,'plane_tiny_reference.tsv'),'w') {|file|file.puts([c.red,c.green,c.blue,c.alpha].join("\t"))}
snap.dispose;plane.dispose;viewport.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
