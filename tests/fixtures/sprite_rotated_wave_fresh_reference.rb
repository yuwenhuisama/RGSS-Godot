output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(32,24);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=160;sprite.y=160;sprite.ox=16;sprite.oy=12
sprite.angle=90;sprite.wave_amp=8;sprite.wave_length=32;sprite.wave_phase=90
8.times {Graphics.update}
snap=Graphics.snap_to_bitmap
File.open(File.join(output,'sprite_rotated_wave_fresh_reference.tsv'),'w') do |file|
  [[150,160],[168,160],[160,148],[160,172]].each do |x,y|
    c=snap.get_pixel(x,y);file.puts([x,y,c.red,c.green,c.blue,c.alpha].join("\t"))
  end
end
snap.dispose;sprite.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
