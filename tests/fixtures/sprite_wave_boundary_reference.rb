output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(32,25);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80;sprite.wave_amp=7
rows=[]
[[32,30,1],[32,210,1],[-32,30,1],[32,30,2]].each do |length,phase,zoom|
  sprite.wave_length=length;sprite.wave_phase=phase;sprite.zoom_x=zoom;sprite.zoom_y=zoom
  sprite.update
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  bands=[80,88,96,104].map {|y|(48..176).select {|x|snap.get_pixel(x,y).red==160}.join(',')}
  rows << [length,phase,zoom,sprite.wave_phase,*bands];snap.dispose
end
File.open(File.join(output,'sprite_wave_boundary_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
