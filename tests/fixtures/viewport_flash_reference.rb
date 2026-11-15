output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
viewport=Viewport.new(80,80,48,48);viewport.z=300
bitmap=Bitmap.new(48,48);bitmap.fill_rect(bitmap.rect,Color.new(160,80,40,255))
sprite=Sprite.new(viewport);sprite.bitmap=bitmap
rows=[]
[0,1,4].each do |duration|
  [false,true].each do |hide|
    viewport.color.set(20,200,100,128)
    viewport.flash(hide ? nil : Color.new(240,20,100,192),duration)
    (duration+2).times do |step|
      viewport.update if step>0
      2.times {Graphics.update}
      snap=Graphics.snap_to_bitmap;c=snap.get_pixel(84,84);v=viewport.color
      rows << [duration,hide,step,c.red,c.green,c.blue,v.red,v.green,v.blue,v.alpha];snap.dispose
    end
  end
end
File.open(File.join(output,'viewport_flash_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
sprite.dispose;viewport.dispose;bitmap.dispose
back.dispose;background.dispose
exit
