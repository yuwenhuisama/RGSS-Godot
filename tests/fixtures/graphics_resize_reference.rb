output=$rgss_compat_output || '.'
rows=[]
[[544,416],[640,480],[320,240],[800,600],[1,1],[0,0],[-1,-1],[544,416]].each do |size|
  begin
    Graphics.resize_screen(*size)
    Graphics.wait(2)
    bitmap=Graphics.snap_to_bitmap
    rows << [*size,Graphics.width,Graphics.height,bitmap.width,bitmap.height]
    bitmap.dispose
  rescue Exception => error
    rows << [*size,error.class.to_s]
  end
end
File.open(File.join(output,'graphics_resize_reference.tsv'),'w') {|file|rows.each {|row|file.puts(row.join("\t"))}}
exit
