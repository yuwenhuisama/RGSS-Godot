output=$rgss_compat_output || '.'
bg=Bitmap.new(544,416);bg.fill_rect(bg.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=bg;back.z=-100
skin=Bitmap.new(128,128)
skin.fill_rect(64,0,16,16,Color.new(220,40,100,255))
skin.fill_rect(112,0,16,16,Color.new(20,180,240,255))
skin.fill_rect(64,48,16,16,Color.new(80,200,20,255))
skin.fill_rect(112,48,16,16,Color.new(160,80,40,255))
skin.fill_rect(80,0,32,16,Color.new(240,180,20,255))
skin.fill_rect(80,48,32,16,Color.new(40,220,220,255))
skin.fill_rect(64,16,16,32,Color.new(200,80,200,255))
skin.fill_rect(112,16,16,32,Color.new(120,120,240,255))
window=Window.new(80,80,64,64);window.windowskin=skin;window.contents_opacity=0;window.arrows_visible=false
rows=[]
[[16,16],[20,16],[24,24],[31,31],[32,32],[48,40],[64,64],[64,16],[16,64],[16,16,128],[16,16,128,1],[16,16,128,2],[16,16,128,3]].each do |width,height,alpha,count|
  if alpha
    skin.fill_rect(64,0,16,16,Color.new(220,40,100,alpha))
    skin.fill_rect(112,0,16,16,Color.new(20,180,240,alpha))
    skin.fill_rect(64,48,16,16,Color.new(80,200,20,alpha))
    skin.fill_rect(112,48,16,16,Color.new(160,80,40,alpha))
  end
  if count
    skin.clear_rect(112,48,16,16)
    skin.clear_rect(64,48,16,16) if count<3
    skin.clear_rect(112,0,16,16) if count<2
  end
  window.width=width;window.height=height
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[0,0],[width-1,0],[0,height-1],[width-1,height-1],[width/2,height/2],[width,0],[0,height]].map {|x,y|c=snap.get_pixel(80+x,80+y);[c.red,c.green,c.blue,c.alpha].join(',')}
  rows << [width,height,*points];snap.dispose
end
File.open(File.join(output,'window_border_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
window.dispose;skin.dispose;back.dispose;bg.dispose
exit
