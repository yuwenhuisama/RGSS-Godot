output = $rgss_compat_output || '.'
b = Bitmap.new(544,416)
b.font.name = 'Arial'
b.font.size = 24
b.font.outline = false
b.font.shadow = false
text = 'Hello AV iiii WWWW 12345'
File.open(File.join(output,'text_width_reference.tsv'),'w') do |f|
  [500,300,261,260,259,258,255,250,245,240,230,220,200,180,160,100].each do |width|
    b.clear
    b.draw_text(20,20,width,40,text)
    xs=[]; ys=[]
    (0...60).each do |y|
      (0...544).each do |x|
        c=b.get_pixel(x,y)
        if c.alpha > 180
          xs << x; ys << y
        end
      end
    end
    f.puts([width,xs.min,xs.max,ys.min,ys.max].join("\t"))
  end
end
b.dispose
exit
