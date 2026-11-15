output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
bitmap=Bitmap.new(32,24);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80
rows=[]
[:plain,:opacity,:color,:tone,:gray,:bush,:add,:subtract,:flash,:flash_update,:flash_end,:hide_flash].each do |mode|
  sprite.opacity=255;sprite.color.set(0,0,0,0);sprite.tone.set(0,0,0,0);sprite.bush_depth=0;sprite.blend_type=0
  case mode
  when :opacity then sprite.opacity=128
  when :color then sprite.color.set(20,200,100,128)
  when :tone then sprite.tone.set(40,-20,60,0)
  when :gray then sprite.tone.set(0,0,0,128)
  when :bush then sprite.bush_depth=12;sprite.bush_opacity=128
  when :add then sprite.blend_type=1
  when :subtract then sprite.blend_type=2
  when :flash then sprite.flash(Color.new(240,20,100,192),4)
  when :flash_update then sprite.update
  when :flash_end then 3.times {sprite.update}
  when :hide_flash then sprite.flash(nil,4)
  end
  8.times {Graphics.update}
  snapshot=Graphics.snap_to_bitmap
  points=[[84,84],[84,100]].map {|x,y|c=snapshot.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [mode,*points]
  snapshot.dispose
end
File.open(File.join(output,'sprite_effect_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;background.dispose
exit
