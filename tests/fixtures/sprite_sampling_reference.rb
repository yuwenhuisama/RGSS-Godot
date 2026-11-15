output=$rgss_compat_output || '.'
background=Bitmap.new(544,416)
background.fill_rect(background.rect,Color.new(48,48,48,255))
back=Sprite.new;back.bitmap=background;back.z=-100
source=Bitmap.new(32,24)
24.times {|y|32.times {|x|source.set_pixel(x,y,(x+y)%2==0 ? Color.new(240,40,20,255) : Color.new(20,180,240,255))}}
source.fill_rect(0,0,32,1,Color.new(255,0,255,255))
source.fill_rect(0,23,32,1,Color.new(0,255,0,255))
source.fill_rect(0,0,1,24,Color.new(255,255,0,255))
source.fill_rect(31,0,1,24,Color.new(0,255,255,255))
sprites=[]
[[120,120,2,1,90],[260,120,1,1,90],[400,120,1,1,180],[120,280,1,1,270],[300,280,1,1,45],[440,280,1,1,30]].each do |x,y,zx,zy,angle|
  sprite=Sprite.new;sprite.bitmap=source;sprite.x=x;sprite.y=y
  sprite.ox=16;sprite.oy=12;sprite.zoom_x=zx;sprite.zoom_y=zy;sprite.angle=angle
  sprites << sprite
end
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'sprite_sampling_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[]
    544.times {|x|c=snapshot.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose
sprites.each {|sprite|sprite.dispose}
source.dispose;back.dispose;background.dispose
exit
