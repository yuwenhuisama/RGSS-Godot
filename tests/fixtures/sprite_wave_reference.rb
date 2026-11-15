output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(32,32);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80
sprite.wave_amp=8;sprite.wave_length=32;sprite.wave_speed=64;sprite.wave_phase=0
rows=[]
[:initial,:graphics_only,:update,:phase90,:amp_zero_update].each do |mode|
  sprite.update if mode==:update
  sprite.wave_phase=90 if mode==:phase90
  if mode==:amp_zero_update
    sprite.wave_amp=0;sprite.update
  end
  8.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  bands=[80,88,96,104].map do |y|
    (64..128).select {|x|snap.get_pixel(x,y).red==160}.join(',')
  end
  rows << [mode,sprite.wave_phase,*bands];snap.dispose
end
File.open(File.join(output,'sprite_wave_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
