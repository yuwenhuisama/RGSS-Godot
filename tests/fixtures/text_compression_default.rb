output=$rgss_compat_output || '.'
['Arial','nsimsun','Courier New'].each do |default|
  Font.default_name=default
  b=Bitmap.new(160,64)
  b.font.name='nsimsun'
  b.font.size=24
  b.font.outline=false
  b.font.shadow=false
  b.draw_text(8,8,80,40,'Hello AV',0)
  xs=[]
  64.times {|y|160.times {|x|xs << x if b.get_pixel(x,y).alpha > 0}}
  File.open(File.join(output,'default_compression.tsv'),'a') {|f|f.puts([default,xs.min,xs.max,xs.size].join("\t"))}
  b.dispose
end
['Arial','nsimsun'].each do |name|
  [13,18,20,26,30].each do |size|
    b=Bitmap.new(240,80)
    b.font.name=name
    b.font.size=size
    b.font.outline=false
    b.font.shadow=false
    text='HHHH'
    full=b.text_size(text).width
    [0.8,0.92].each do |ratio|
      b.clear
      b.draw_text(8,8,(full*ratio).to_i,60,text)
      pixels=[]
      80.times do |y|
        240.times {|x|c=b.get_pixel(x,y);pixels.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
      end
      File.open(File.join(output,"nominal_#{name}_#{size}_#{ratio}.rgba"),'wb') {|file|file.write(pixels.pack('C*'))}
    end
    b.dispose
  end
end
exit
