output=$rgss_compat_output || '.'
background=Bitmap.new(544,416)
background.fill_rect(background.rect,Color.new(0,0,0))
background_sprite=Sprite.new
background_sprite.bitmap=background
background_sprite.z=-1000
sizes=[[512,384],[512,384],[512,256],[512,480],[256,512],[512,512],[512,512],[512,512],[512,512]]
bitmaps=sizes.each_with_index.map do |size,index|
  bitmap=Bitmap.new(*size)
  (size[1]/16).times do |y|
    (size[0]/16).times do |x|
      bitmap.fill_rect(x*16,y*16,16,16,Color.new((x*7+index*23)%256,(y*11+index*31)%256,(x*13+y*17+index*19)%256))
      if $tilemap_probe_origin
        16.times do |dy|
          16.times {|dx|bitmap.set_pixel(x*16+dx,y*16+dy,Color.new(dx*16,dy*16,index*20))}
        end
      end
    end
  end
  bitmap
end
viewport=Viewport.new(0,0,544,416)
tilemap=Tilemap.new(viewport)
bitmaps.each_with_index {|bitmap,index|tilemap.bitmaps[index]=bitmap}
tilemap.flags=Table.new(8192)
ids=(0...1024).to_a+(1536...1664).to_a+(2048...8192).to_a
ids=[2288,2292,4352,4368,6288] if $tilemap_probe_origin
ids=(0...16).map {|slot|2048+slot*48} if $tilemap_probe_animation
if $tilemap_probe_tables
  ids=(2816...4352).to_a
  ids.each {|id|tilemap.flags[id]=128}
end
rows=[]
ids.each_slice(221) do |page|
  map=Table.new(17,13,4)
  page.each_with_index {|id,index|map[index%17,index/17,0]=id}
  tilemap.map_data=map
  3.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  if $tilemap_probe_render
    File.open(File.join(output,"tilemap_page_#{rows.length / 221}.rgba"),'wb') do |file|
      416.times do |y|
        bytes=[]
        544.times do |x|
          color=snap.get_pixel(x,y)
          bytes.concat([color.red.to_i,color.green.to_i,color.blue.to_i,color.alpha.to_i])
        end
        file.write(bytes.pack('C*'))
      end
    end
  end
  page.each_with_index do |id,index|
    offsets=$tilemap_probe_origin ? [[1,2],[7,11],[20,5],[30,29]] : [[8,8],[24,8],[8,24],[24,24]]
    offsets=[[8,4],[24,4],[8,12],[24,12],[8,20],[24,20],[8,28],[24,28]] if $tilemap_probe_tables
    pixels=offsets.map do |offset|
      c=snap.get_pixel(index%17*32+offset[0],index/17*32+offset[1])
      [c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join(',')
    end
    rows << [id,*pixels]
  end
  snap.dispose
end
if $tilemap_probe_animation
  100.times do |frame|
    tilemap.update
    Graphics.update
    snap=Graphics.snap_to_bitmap
    pixels=16.times.map do |slot|
      c=snap.get_pixel(slot*32+8,8)
      [c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join(',')
    end
    rows << ['animation',frame+1,*pixels]
    snap.dispose
  end
end
File.open(File.join(output,'tilemap_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
tilemap.dispose;viewport.dispose;bitmaps.each {|bitmap|bitmap.dispose};background_sprite.dispose;background.dispose
exit
