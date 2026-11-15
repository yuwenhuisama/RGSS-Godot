output=$rgss_compat_output || '.'
background=Bitmap.new(544,416);background.fill_rect(background.rect,Color.new(0,0,0))
background_sprite=Sprite.new;background_sprite.bitmap=background;background_sprite.z=-1000
if $tilemap_probe_render
  File.open(File.join(output,'tilemap_scroll_frames.rgba'),'wb') {|file|}
end
def capture_scroll_frame(snapshot)
  return unless $tilemap_probe_render
  output=$rgss_compat_output || '.'
  File.open(File.join(output,'tilemap_scroll_frames.rgba'),'ab') do |file|
    416.times do |y|
      bytes=[]
      544.times do |x|
        c=snapshot.get_pixel(x,y)
        bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])
      end
      file.write(bytes.pack('C*'))
    end
  end
end
atlas=Bitmap.new(512,512)
atlas.fill_rect(32,0,32,32,Color.new(200,40,60))
atlas.fill_rect(64,0,32,32,Color.new(20,180,80))
atlas.fill_rect(96,0,32,32,Color.new(40,80,220))
viewport=Viewport.new(0,0,544,416)
tilemap=Tilemap.new(viewport)
tilemap.bitmaps[5]=atlas
map=Table.new(2,2,4)
map[0,0,0]=1;map[1,0,0]=2;map[0,1,0]=3;map[1,1,0]=1
tilemap.map_data=map
tilemap.flags=Table.new(8192)
rows=[]
[[0,0],[1,0],[31,0],[32,0],[63,0],[64,0],[-1,0],[-32,0],[0,1],[0,31],[0,32],[0,-1],[17,19]].each do |origin|
  tilemap.ox=origin[0];tilemap.oy=origin[1]
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  pixels=[[0,0],[15,15],[31,31],[32,32],[63,63],[100,100],[543,415]].map do |point|
    c=snap.get_pixel(*point)
    [c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join(',')
  end
  rows << [*origin,*pixels]
  capture_scroll_frame(snap)
  snap.dispose
end
tilemap.ox=0;tilemap.oy=0
actor_bitmap=Bitmap.new(32,32);actor_bitmap.fill_rect(actor_bitmap.rect,Color.new(240,220,20))
actor=Sprite.new(viewport);actor.bitmap=actor_bitmap
[0,100,200,201].each do |z|
  actor.z=z
  [0,16].each do |flag|
    flags=Table.new(8192);flags[1]=flag;tilemap.flags=flags
    2.times {Graphics.update}
    snap=Graphics.snap_to_bitmap;c=snap.get_pixel(16,16)
    rows << ['occlusion',z,flag,c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i]
    capture_scroll_frame(snap)
    snap.dispose
  end
end
actor.visible=false
flags=Table.new(8192);tilemap.flags=flags
map[0,0,0]=1
map[0,0,1]=0;map[0,0,2]=0
tilemap.map_data=map
def scroll_reference_pixels(rows,name)
  2.times {Graphics.update}
  snap=Graphics.snap_to_bitmap
  pixels=[[8,8],[24,8],[8,24],[24,24]].map do |point|
    c=snap.get_pixel(*point)
    [c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join(',')
  end
  rows << [name,*pixels]
  capture_scroll_frame(snap)
  snap.dispose
end
scroll_reference_pixels(rows,'mutation_before')
map[0,0,0]=2
scroll_reference_pixels(rows,'mutation_after')
16.times do |shadow|
  data=Table.new(2,2,4);data[0,0,0]=1;data[0,0,3]=shadow
  tilemap.map_data=data
  scroll_reference_pixels(rows,"shadow_#{shadow}")
end
data=Table.new(2,2,4);data[0,0,0]=1;data[0,0,3]=15;data[0,0,2]=2
tilemap.map_data=data
scroll_reference_pixels(rows,'upper_layer_over_shadow')
data=Table.new(2,2,4);data[0,0,0]=1;tilemap.map_data=data
flags=Table.new(8192);tilemap.flags=flags
actor.visible=true;actor.z=100
scroll_reference_pixels(rows,'flags_before')
flags[1]=16
scroll_reference_pixels(rows,'flags_after')
flags[1]=0;actor.visible=false
flash=Table.new(2,2);tilemap.flash_data=flash
scroll_reference_pixels(rows,'flash_before')
flash[0,0]=0x0f0
scroll_reference_pixels(rows,'flash_after')
40.times do |frame|
  tilemap.update
  Graphics.update
  snap=Graphics.snap_to_bitmap;c=snap.get_pixel(8,8)
  rows << ['flash_cycle',frame+1,c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i]
  capture_scroll_frame(snap)
  snap.dispose
end
File.open(File.join(output,'tilemap_scroll_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
actor.dispose;actor_bitmap.dispose;tilemap.dispose;viewport.dispose;atlas.dispose;background_sprite.dispose;background.dispose
exit
