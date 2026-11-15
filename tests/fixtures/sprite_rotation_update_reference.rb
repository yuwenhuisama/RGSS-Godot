output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
bitmap=Bitmap.new(32,24);bitmap.fill_rect(bitmap.rect,Color.new(240,40,20,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=160;sprite.y=160;sprite.ox=16;sprite.oy=12;sprite.angle=90
rows=[]
4.times do |step|
  case step
  when 1 then bitmap.fill_rect(bitmap.rect,Color.new(20,180,240,255))
  when 2 then sprite.angle=0;sprite.src_rect.width=8
  when 3 then sprite.angle=45;sprite.x=220
  end
  8.times {Graphics.update}
  snapshot=Graphics.snap_to_bitmap
  c=snapshot.get_pixel(step==3 ? 212 : step==2 ? 148 : 160,step==3 ? 168 : 160)
  rows << [step,c.red,c.green,c.blue,c.alpha]
  snapshot.dispose
end
File.open(File.join(output,'sprite_rotation_update_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;background.dispose
exit
