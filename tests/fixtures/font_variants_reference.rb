output = $rgss_compat_output || '.'
bitmap = Bitmap.new(200,60)
File.open(File.join(output,'font_variants_reference.tsv'),'w') do |file|
  ['Arial','nsimsun'].each do |name|
    bitmap.font.name=name
    [12,18,24,32,48].each do |size|
      bitmap.font.size=size
      ['Hello AV','中文测试','Hello中文123','A V','',123,'A','V','AV','Hello',' '].each do |text|
        [false,true].each do |bold|
          bitmap.font.bold=bold
          rect=bitmap.text_size(text)
          file.puts([name,size,text,bold,rect.width,rect.height].join("\t"))
        end
      end
    end
  end
end
bitmap.dispose
exit
