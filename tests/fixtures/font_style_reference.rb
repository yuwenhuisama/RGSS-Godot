output = $rgss_compat_output || '.'
['normal','bold','italic','shadow','outline'].each do |style|
  ['H','A','g','Hello AV','.','l','W'].each_with_index do |text,index|
    bitmap=Bitmap.new(160,64)
    bitmap.font.name='Arial'
    bitmap.font.size=24
    bitmap.font.bold=style=='bold'
    bitmap.font.italic=style=='italic'
    bitmap.font.shadow=style=='shadow'
    bitmap.font.outline=style=='outline'
    bitmap.draw_text(16,8,128,40,text)
    File.open(File.join(output,"font_style_#{style}_#{index}.rgba"),'wb') do |file|
      bitmap.height.times do |y|
        row=[]
        bitmap.width.times do |x|
          c=bitmap.get_pixel(x,y)
          row.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])
        end
        file.write(row.pack('C*'))
      end
    end
    bitmap.dispose
  end
end
File.open(File.join(output,'font_style_done.txt'),'w') { |f| f.write('FONT_STYLE_DONE') }
exit
