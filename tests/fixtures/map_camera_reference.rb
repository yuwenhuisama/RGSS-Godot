output=$rgss_compat_output || '.'
rows=[]
begin
$data_system=RPG::System.new unless $data_system
[[10,8],[40,30]].each do |size|
  4.times do |mode|
    map=Game_Map.new
    data=RPG::Map.new(*size)
    data.scroll_type=mode
    map.instance_variable_set(:@map,data)
    [[-5,-7],[0,0],[12.5,9.25],[100,100]].each do |position|
      map.set_display_pos(*position)
      rows << [*size,mode,'set',*position,map.display_x,map.display_y]
    end
    [:scroll_down,:scroll_left,:scroll_right,:scroll_up].each do |direction|
      map.set_display_pos(0,0)
      map.send(direction,100)
      rows << [*size,mode,direction,map.display_x,map.display_y]
    end
  end
end
File.open(File.join(output,'map_camera_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
rescue Exception => error
  File.open(File.join(output,'map_camera_error.txt'),'w') {|file|file.puts(error.class.to_s);file.puts(error.message);file.puts(error.backtrace)}
  raise if $rgss_compat_output
end
exit unless $rgss_compat_output
