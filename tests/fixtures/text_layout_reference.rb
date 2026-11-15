# Same text layout inputs in original RGSS300 and Godot.
output=$rgss_compat_output || '.'
cases=[
  ['left',8,8,144,40,'Hello AV',0],
  ['center',8,8,144,40,'Hello AV',1],
  ['right',8,8,144,40,'Hello AV',2],
  ['narrow',8,8,32,40,'Hello AV',1],
  ['clipped',-8,-4,80,24,'Hello AV',2],
  ['short_height',8,8,144,8,'Hello AV',0],
  ['mixed',8,8,144,40,"ABC中文123",0],
  ['linebreak',8,8,144,40,"A\nB\rC",0],
  ['zero',8,8,0,40,'Hello',0],
  ['spaces',8,8,144,40,'A B C',0],
  ['narrow_left',8,8,32,40,'Hello AV',0],
  ['short_height_tall',8,8,144,24,'Hello AV',0],
  ['linebreak_boxes',8,8,144,40,"A□□B□C",0],
  ['linebreak_nulls',8,8,144,40,"A\0B\0C",0],
  ['linebreak_advance',8,8,144,40,"A  B  C",0],
  ['clipped_origin_zero',0,0,80,24,'Hello AV',2],
  ['width80_left',0,0,80,24,'Hello AV',0],
  ['width32_H',8,8,32,40,'H',0],
  ['width32_all',8,8,32,40,'Hello AV',2],
  ['controls_only',8,8,144,40,"\n\r",0]
]
[16,24,40,48,56,64,72,73,76,77,78,79,80,84,87,88,89,96,104].each do |width|
  cases << ["width_#{width}",8,8,width,40,'Hello AV',0]
end
["\n","\r",'H',"\u007f"].each_with_index do |text,index|
  cases << ["control_#{index}",8,8,144,40,text,0]
end
["AB","A\nB","A\rB","A\nB\rC","A\nBC"].each_with_index do |text,index|
  cases << ["control_pair_#{index}",8,8,144,40,text,0]
end
[24,32,40,44].each {|width|cases << ["size12_#{width}",8,8,width,40,'Hello AV',0]}
[32,40,44,47].each {|width|cases << ["fourH_#{width}",8,8,width,40,'HHHH',0]}
[72,84,96,108,120,128,132,136].each {|width|cases << ["longH_#{width}",8,8,width,40,'HHHHHHHHHHHH',0]}
[36,37,38,39,41,42,43].each {|width|cases << ["fourH_boundary_#{width}",8,8,width,40,'HHHH',0]}
cases.each do |name,x,y,w,h,text,align|
  bitmap=Bitmap.new(160,64)
  bitmap.font.name='nsimsun'
  bitmap.font.size=24
  bitmap.font.size=12 if name.start_with?('size12_')
  bitmap.font.outline=false
  bitmap.font.shadow=false
  bitmap.draw_text(x,y,w,h,text,align)
  File.open(File.join(output,"text_layout_#{name}.rgba"),'wb') do |file|
    bitmap.height.times do |py|
      bytes=[]
      bitmap.width.times {|px|c=bitmap.get_pixel(px,py);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
      file.write(bytes.pack('C*'))
    end
  end
  bitmap.dispose
end
exit
