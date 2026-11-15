output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128);skin.fill_rect(64,64,32,32,Color.new(240,180,20,255))
window=Window.new(80,80,128,96);window.windowskin=skin;window.cursor_rect.set(20,20,24,16)
rows=[]
[0,255].each do |background|
bg.fill_rect(bg.rect,Color.new(background,background,background,255))
window.dispose
window=Window.new(80,80,128,96);window.windowskin=skin;window.cursor_rect.set(20,20,24,16)
41.times do |step|
  window.update if step>0
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(110,110)
  rows << [background,step,c.red,c.green,c.blue,c.alpha];snap.dispose
end
end
window.active=false
2.times {Graphics.update}
snap=Graphics.snap_to_bitmap;c=snap.get_pixel(110,110);rows << ['inactive',c.red,c.green,c.blue,c.alpha];snap.dispose
File.open(File.join(output,'window_cursor_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
window.dispose;skin.dispose;back.dispose;bg.dispose
exit
