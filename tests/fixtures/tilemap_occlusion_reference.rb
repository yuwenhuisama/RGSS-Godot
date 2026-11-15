output=$rgss_compat_output || '.'
atlas=Bitmap.new(512,512);atlas.fill_rect(32,0,32,32,Color.new(200,40,60))
viewport=Viewport.new(0,0,544,416)
tilemap=Tilemap.new(viewport);tilemap.bitmaps[5]=atlas
bitmap=Bitmap.new(32,32);bitmap.fill_rect(bitmap.rect,Color.new(240,220,20))
actor=Sprite.new(viewport);actor.bitmap=bitmap
rows=[]
sheet=Bitmap.new(6*32,6*32) if $tilemap_probe_render
3.times do |layer|
  map=Table.new(17,13,4);map[0,0,layer]=1;tilemap.map_data=map
  [0,16].each do |flag|
    flags=Table.new(8192);flags[1]=flag;tilemap.flags=flags
    [-1,0,100,199,200,201].each do |z|
      actor.z=z
      2.times {Graphics.update}
      snap=Graphics.snap_to_bitmap;c=snap.get_pixel(16,16)
      rows << [layer,flag,z,c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i]
      sheet.blt((rows.length-1)%6*32,(rows.length-1)/6*32,snap,Rect.new(0,0,32,32)) if sheet
      snap.dispose
    end
  end
end
File.open(File.join(output,'tilemap_occlusion_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
if sheet
  File.open(File.join(output,'tilemap_occlusion_grid.rgba'),'wb') do |file|
    192.times do |y|
      bytes=[];192.times {|x|c=sheet.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
      file.write(bytes.pack('C*'))
    end
  end
  sheet.dispose
end
actor.dispose;bitmap.dispose;tilemap.dispose;viewport.dispose;atlas.dispose
exit
