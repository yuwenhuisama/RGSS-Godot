output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
bitmap=Bitmap.new(16,16);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new;sprite.bitmap=bitmap;sprite.x=80;sprite.y=80
rows=[]
[0,1,2,4].each do |duration|
  [false,true].each do |hide|
    sprite.flash(hide ? nil : Color.new(240,20,100,192),duration)
    (duration+2).times do |step|
      sprite.update if step>0
      2.times {Graphics.update}
      snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84)
      rows << [duration,hide,step,c.red,c.green,c.blue,c.alpha];snap.dispose
    end
  end
end
File.open(File.join(output,'sprite_flash_duration_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;bitmap.dispose;back.dispose;bg.dispose
exit
