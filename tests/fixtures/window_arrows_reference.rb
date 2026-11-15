output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
[[88,16,16,8],[88,40,16,8],[80,24,8,16],[104,24,8,16]].each_with_index {|r,i|skin.fill_rect(*r,Color.new(40+i*50,180-i*30,220-i*40,255))}
contents=Bitmap.new(200,160)
window=Window.new(80,80,128,96);window.windowskin=skin;window.contents=contents
rows=[]
[[0,0,true,255],[40,40,true,255],[88,80,true,255],[40,40,false,255],[40,40,true,128],[40,40,true,0]].each do |ox,oy,visible,opacity|
  window.ox=ox;window.oy=oy;window.arrows_visible=visible;window.opacity=opacity
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[144,84],[144,168],[84,128],[200,128]].map {|x,y|c=snap.get_pixel(x,y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [ox,oy,visible,opacity,*points];snap.dispose
end
File.open(File.join(output,'window_arrows_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
window.dispose;skin.dispose;contents.dispose;back.dispose;bg.dispose
exit
