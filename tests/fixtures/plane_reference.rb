output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(8,8)
bitmap.fill_rect(0,0,4,4,Color.new(160,80,40,255))
bitmap.fill_rect(4,0,4,4,Color.new(20,180,240,255))
bitmap.fill_rect(0,4,4,4,Color.new(220,40,100,255))
bitmap.fill_rect(4,4,4,4,Color.new(80,200,20,255))
viewport=Viewport.new(80,80,24,24);viewport.z=10
plane=Plane.new(viewport);plane.bitmap=bitmap
rows=[]
modes=$plane_reference_modes || [:plain,:scroll,:zoom,:viewport_scroll,:color,:tone,:opacity,:add,:subtract,:fractional_zoom,:negative_scroll,:zoom_viewport_scroll,:hidden,:no_bitmap,:zero_zoom,:negative_zoom,:tiny_zoom]
modes.each do |mode|
  plane.ox=0;plane.oy=0;plane.zoom_x=1;plane.zoom_y=1;plane.opacity=255;plane.blend_type=0
  plane.color.set(0,0,0,0);plane.tone.set(0,0,0,0);viewport.ox=0;viewport.oy=0
  plane.visible=true;plane.bitmap=bitmap
  case mode
  when :scroll then plane.ox=3;plane.oy=5
  when :zoom then plane.zoom_x=2;plane.zoom_y=2;plane.ox=3;plane.oy=5
  when :viewport_scroll then viewport.ox=5;viewport.oy=3
  when :color then plane.color.set(20,200,100,128)
  when :tone then plane.tone.set(40,-20,60,128)
  when :opacity then plane.opacity=128
  when :add then plane.opacity=128;plane.blend_type=1
  when :subtract then plane.opacity=128;plane.blend_type=2
  when :fractional_zoom then plane.zoom_x=1.5;plane.zoom_y=0.75;plane.ox=5;plane.oy=3
  when :negative_scroll then plane.ox=-5;plane.oy=-3
  when :zoom_viewport_scroll then plane.zoom_x=2;plane.zoom_y=2;viewport.ox=5;viewport.oy=3
  when :hidden then plane.visible=false
  when :no_bitmap then plane.bitmap=nil
  when :zero_zoom then plane.zoom_x=0
  when :negative_zoom then plane.zoom_x=-1
  when :tiny_zoom then plane.zoom_x=0.01
  end
  File.open(File.join(output,'plane_mode_progress.txt'),'w') {|file|file.puts(mode)}
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[80,80],[84,80],[80,84],[84,84],[100,100],[103,103],[104,104],[76,76]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [mode,*points];snap.dispose
  File.open(File.join(output,'plane_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
end
File.open(File.join(output,'plane_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
plane.dispose;viewport.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
