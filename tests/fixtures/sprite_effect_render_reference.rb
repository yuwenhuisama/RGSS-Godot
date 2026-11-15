output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
bitmap=Bitmap.new(32,32)
bitmap.fill_rect(0,0,16,32,Color.new(160,80,40,255))
bitmap.fill_rect(16,0,16,32,Color.new(20,180,240,255))
bitmap.fill_rect(4,4,8,8,Color.new(255,255,255,255))
sprites=[]
[:plain,:opacity,:color,:gray,:bush,:add,:subtract,:flash,:wave,:rotated_wave].each_with_index do |mode,index|
  sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=48+(index%5)*104;sprite.y=80+(index/5)*160
  sprite.zoom_x=2;sprite.zoom_y=2
  case mode
  when :opacity then sprite.opacity=128
  when :color then sprite.color.set(20,200,100,128)
  when :gray then sprite.tone.set(0,0,0,128)
  when :bush then sprite.bush_depth=16;sprite.bush_opacity=128
  when :add then sprite.blend_type=1
  when :subtract then sprite.blend_type=2
  when :flash then sprite.flash(Color.new(240,20,100,192),4)
  when :wave then sprite.wave_amp=8;sprite.wave_length=32;sprite.wave_phase=90
  when :rotated_wave then sprite.angle=45;sprite.ox=16;sprite.oy=16;sprite.wave_amp=($rgss_no_wave ? 0 : 8);sprite.wave_length=32;sprite.wave_phase=90
  end
  sprites << sprite
end
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'sprite_effect_render_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[]
    544.times {|x|c=snapshot.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose;sprites.each {|sprite|sprite.dispose};bitmap.dispose;back.dispose;background.dispose
exit
