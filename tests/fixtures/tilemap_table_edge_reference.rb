output=$rgss_compat_output || '.'
atlas=Bitmap.new(512,384)
24.times do |y|
  32.times {|x|atlas.fill_rect(x*16,y*16,16,16,Color.new(x*7%256,y*11%256,(x*13+y*17)%256))}
end
viewport=Viewport.new(0,0,544,416)
tilemap=Tilemap.new(viewport)
tilemap.bitmaps[1]=atlas
flags=Table.new(8192)
48.times {|shape|flags[2816+shape]=128}
tilemap.flags=flags
rows=[]
48.times do |shape|
  map=Table.new(17,13,4)
  map[0,0,0]=2816+shape
  map[0,1,0]=2863
  tilemap.map_data=map
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  points=[[8,28],[24,28],[8,32],[24,32],[8,36],[24,36],[8,40],[24,40]]
  pixels=points.map do |point|
    c=snap.get_pixel(*point)
    [c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join(',')
  end
  rows << [shape,*pixels]
  snap.dispose
end
File.open(File.join(output,'tilemap_table_edge_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
tilemap.dispose;viewport.dispose;atlas.dispose
exit
