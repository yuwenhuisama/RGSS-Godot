output=$rgss_compat_output || '.'
canvas=Bitmap.new(544,416)
canvas.fill_rect(0,0,544,416,Color.new(48,48,48,255))
cases=[
  [144,40,'Hello AV',0], [144,40,'Hello AV',1], [144,40,'Hello AV',2],
  [32,40,'Hello AV',0], [80,24,'Hello AV',2], [144,8,'Hello AV',0],
  [144,40,'ABC中文123',0], [144,40,"A\nB\rC",0], [144,40,'A B C',0]
]
cases.each_with_index do |entry,index|
  w,h,text,align=entry
  tile=Bitmap.new(160,64)
  tile.font.name='nsimsun'
  tile.font.size=24
  tile.font.outline=false
  tile.font.shadow=false
  tile.draw_text(8,8,w,h,text,align)
  canvas.blt(16+(index%3)*176,32+(index/3)*112,tile,tile.rect)
  tile.dispose
end
sprite=Sprite.new
sprite.bitmap=canvas
8.times {Graphics.update}
snapshot=Graphics.snap_to_bitmap
File.open(File.join(output,'text_layout_render_reference.rgba'),'wb') do |file|
  snapshot.height.times do |y|
    bytes=[]
    snapshot.width.times {|x|c=snapshot.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
    file.write(bytes.pack('C*'))
  end
end
snapshot.dispose
sprite.dispose
canvas.dispose
exit
