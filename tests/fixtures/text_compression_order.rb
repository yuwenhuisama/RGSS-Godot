output=$rgss_compat_output || '.'
[[80,32,96,80],[96,80,32,80]].each_with_index do |widths,group|
  widths.each_with_index do |width,index|
    b=Bitmap.new(160,64)
    b.font.name='nsimsun'
    b.font.size=24
    b.font.outline=false
    b.font.shadow=false
    b.draw_text(8,8,width,40,'Hello AV',0)
    File.open(File.join(output,"compression_order_#{group}_#{index}.rgba"),'wb') do |file|
      64.times do |y|
        bytes=[]
        160.times {|x|c=b.get_pixel(x,y);bytes.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
        file.write(bytes.pack('C*'))
      end
    end
    b.dispose
  end
end
['nsimsun','Arial'].each_with_index do |font_name,group|
  [60,70,80,88,94,95,96].each do |width|
    b=Bitmap.new(160,64)
    b.font.name=font_name
    b.font.size=24
    b.font.outline=false
    b.font.shadow=false
    text='Hello AV'
    measured=b.text_size(text)
    b.draw_text(8,8,width,40,text,0)
    xs=[]
    64.times {|y|160.times {|x|xs << x if b.get_pixel(x,y).alpha > 0}}
    File.open(File.join(output,'compression_fonts.tsv'),'a') {|f|f.puts([font_name,width,measured.width,measured.height,xs.min,xs.max,xs.size].join("\t"))}
    b.dispose
  end
end
['HHHH','HHHHHHHHHHHH','Hello AV'].each do |text|
  [39,40,43,44,78,79,87,88,119,120,131,132].each do |width|
    b=Bitmap.new(160,64)
    b.font.name='nsimsun'
    b.font.size=24
    b.font.outline=false
    b.font.shadow=false
    measured=b.text_size(text)
    b.draw_text(8,8,width,40,text,0)
    xs=[]
    64.times {|y|160.times {|x|xs << x if b.get_pixel(x,y).alpha > 0}}
    File.open(File.join(output,'compression_measure.tsv'),'a') {|f|f.puts([text,width,measured.width,xs.min,xs.max].join("\t"))}
    b.dispose
  end
end
exit
