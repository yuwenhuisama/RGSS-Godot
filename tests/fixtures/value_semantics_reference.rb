output=$rgss_compat_output || '.'
rows=[]
[[2,2,0],[2,2,2]].each do |dims|
  t=Table.new(*dims)
  (0...[dims[2],1].max).each { |z| (0...dims[1]).each { |y| (0...dims[0]).each { |x| t[x,y,z]=x+y*10+z*100+1 } } }
  t.resize(3,3,dims[2])
  rows << ['table_resize',dims.join(','),t[0,0,0],t[1,0,0],t[0,1,0],t[1,1,0],t[2,0,0],t[1,1,1]]
end
c=Color.new(-1,300,12,400)
rows << ['color_clamp',c.red,c.green,c.blue,c.alpha]
tone=Tone.new(-400,400,12,400)
rows << ['tone_clamp',tone.red,tone.green,tone.blue,tone.gray]
r=Rect.new(1,2,-3,-4)
rows << ['rect_negative',r.x,r.y,r.width,r.height]
c.red=-20; c.green=300; c.alpha=-10
rows << ['color_setters',c.red,c.green,c.alpha]
c.set(-30,400,12,-10)
rows << ['color_set',c.red,c.green,c.blue,c.alpha]
tone.red=-400; tone.gray=-20
rows << ['tone_setters',tone.red,tone.gray]
tone.set(-400,400,12,-20)
rows << ['tone_set',tone.red,tone.green,tone.blue,tone.gray]
File.open(File.join(output,'value_semantics_reference.tsv'),'w'){|f|rows.each{|row|f.puts(row.join("\t"))}}
exit
