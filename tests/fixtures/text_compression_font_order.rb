output=$rgss_compat_output || '.'
[['Arial','nsimsun'],['nsimsun','Arial'],['nsimsun','nsimsun']].each_with_index do |names,index|
  b=Bitmap.new(160,64)
  b.font.size=24
  b.font.name=names[0]
  b.text_size('Hello AV')
  b.font.name=names[1]
  b.font.outline=false
  b.font.shadow=false
  b.draw_text(8,8,80,40,'Hello AV',0)
  xs=[]
  64.times {|y|160.times {|x|xs << x if b.get_pixel(x,y).alpha > 0}}
  File.open(File.join(output,'font_order.tsv'),'a') {|f|f.puts([index,names.join('->'),xs.min,xs.max,xs.size].join("\t"))}
  b.dispose
end
['Arial','Courier New','Times New Roman','nsimsun'].each do |name|
  [12,24,32].each do |size|
    [0.8,0.92].each do |ratio|
      b=Bitmap.new(240,80)
      b.font.name=name
      b.font.size=size
      b.font.outline=false
      b.font.shadow=false
      text='HHHH'
      measured=b.text_size(text)
      width=(measured.width*ratio).to_i
      b.draw_text(8,8,width,60,text,0)
      xs=[]
      80.times {|y|240.times {|x|xs << x if b.get_pixel(x,y).alpha > 0}}
      File.open(File.join(output,'font_size_compression.tsv'),'a') {|f|f.puts([name,size,ratio,measured.width,width,xs.min,xs.max,xs.size].join("\t"))}
      b.dispose
    end
  end
end
exit
