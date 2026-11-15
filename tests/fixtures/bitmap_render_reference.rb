output=$rgss_compat_output || '.'
canvas=Bitmap.new(544,416)
canvas.fill_rect(0,0,544,416,Color.new(48,48,48,255))
tiles=[]
6.times do |index|
  tile=Bitmap.new(96,96)
  tile.gradient_fill_rect(0,0,96,96,Color.new(240,80,20,255),Color.new(20,80,220,128),false)
  tile.fill_rect(24,24,48,48,Color.new(40,210,90,128))
  case index
  when 1 then tile.hue_change(90)
  when 2 then tile.blur
  when 3 then tile.radial_blur(90,9)
  when 4 then tile.clear_rect(Rect.new(24,24,48,48))
  when 5
    source=tile
    tile=Bitmap.new(96,96)
    tile.stretch_blt(Rect.new(0,0,96,96),source,Rect.new(16,16,64,64),128)
    source.dispose
  end
  canvas.blt(56+(index%3)*160,48+(index/3)*160,tile,tile.rect)
  tiles << tile
end
sprite=Sprite.new
sprite.bitmap=canvas
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'bitmap_render_reference.rgba'),'wb') do |file|
  snapshot.height.times do |y|
    bytes=[]
    snapshot.width.times {|x|c=snapshot.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose
sprite.dispose
tiles.each {|tile|tile.dispose}
canvas.dispose
exit
