output=$rgss_compat_output || '.'
background=Bitmap.new(544,416)
background.fill_rect(0,0,544,416,Color.new(48,48,48,255))
back=Sprite.new
back.bitmap=background
back.z=-100
source=Bitmap.new(32,24)
source.fill_rect(0,0,16,24,Color.new(240,40,20,255))
source.fill_rect(16,0,16,24,Color.new(20,180,240,255))
source.fill_rect(4,4,8,8,Color.new(255,255,255,255))
sprites=[]
[[80,80,0,0,1,1,0,false],[180,80,16,12,2,2,0,false],[300,80,16,12,2,1,90,false],[440,80,16,12,1,2,45,false],[80,220,8,4,2,2,0,true],[200,220,16,12,-1,1,0,false],[300,240,16,12,1,1,180,false],[440,240,16,12,1,1,270,false]].each do |x,y,ox,oy,zx,zy,angle,mirror|
  sprite=Sprite.new
  sprite.bitmap=source
  sprite.x=x;sprite.y=y;sprite.ox=ox;sprite.oy=oy
  sprite.zoom_x=zx;sprite.zoom_y=zy;sprite.angle=angle;sprite.mirror=mirror
  sprites << sprite
end
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'sprite_transform_reference.rgba'),'wb') do |file|
  416.times do |y|
    bytes=[]
    544.times {|x|c=snapshot.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose
sprites.each {|sprite|sprite.dispose}
source.dispose
back.dispose
background.dispose
exit
