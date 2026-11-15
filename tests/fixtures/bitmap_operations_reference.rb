output=$rgss_compat_output || '.'
rows=[]
[[0,8],[-1,8],[8,0]].each_with_index do |size,index|
  begin
    invalid=Bitmap.new(*size)
    rows << ["invalid_size_#{index}",invalid.width,invalid.height]
    invalid.dispose
  rescue => error
    rows << ["invalid_size_#{index}",error.class.name]
  end
end
def probe_pixels(bitmap)
  [[0,0],[1,1],[2,2],[3,3],[7,7]].map { |x,y| c=bitmap.get_pixel(x,y); [c.red,c.green,c.blue,c.alpha].join(',') }
end
bitmap=Bitmap.new(8,8)
rows << ['new',*probe_pixels(bitmap)]
bitmap.fill_rect(0,0,8,8,Color.new(100,50,20,255))
source=Bitmap.new(4,4)
source.fill_rect(0,0,4,4,Color.new(20,150,200,128))
bitmap.blt(1,1,source,Rect.new(0,0,4,4),128)
rows << ['blt',*probe_pixels(bitmap)]
bitmap.clear
bitmap.stretch_blt(Rect.new(0,0,8,8),source,Rect.new(0,0,4,4))
rows << ['stretch',*probe_pixels(bitmap)]
bitmap.clear
bitmap.gradient_fill_rect(0,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255),false)
rows << ['gradient',*probe_pixels(bitmap)]
bitmap.blur
rows << ['blur',*probe_pixels(bitmap)]
bitmap.hue_change(120)
rows << ['hue_gray',*probe_pixels(bitmap)]
bitmap.clear_rect(0,0,2,2)
rows << ['clear_rect',*probe_pixels(bitmap)]
bitmap.clear
8.times do |y|
  8.times do |x|
    bitmap.set_pixel(x,y,Color.new(x*31,y*31,(x+y)*15,(x*17+y*13)%256))
  end
end
bitmap.hue_change(120)
rows << ['hue_color',*probe_pixels(bitmap)]
bitmap.radial_blur(30,5)
rows << ['radial',*probe_pixels(bitmap)]
bitmap.clear
bitmap.blt(-1,-1,source,Rect.new(-1,-1,6,6))
rows << ['blt_clipped',*probe_pixels(bitmap)]
bitmap.clear
bitmap.gradient_fill_rect(-2,0,8,8,Color.new(0,20,100,64),Color.new(255,220,0,192),true)
rows << ['gradient_vertical_clipped',*probe_pixels(bitmap)]
bitmap.clear
bitmap.gradient_fill_rect(-2,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255),false)
rows << ['gradient_horizontal_clipped',*probe_pixels(bitmap)]
[[120,Color.new(255,0,0,255)],[120,Color.new(31,31,30,255)],[90,Color.new(200,80,10,128)],[-90,Color.new(200,80,10,128)],[0,Color.new(200,80,10,128)],[360,Color.new(200,80,10,128)],[1,Color.new(255,0,0,255)],[60,Color.new(200,80,10,128)],[180,Color.new(200,80,10,128)]].each_with_index do |pair,index|
  bitmap.fill_rect(0,0,8,8,pair[1])
  bitmap.hue_change(pair[0])
  rows << ["hue_probe_#{index}",*probe_pixels(bitmap)]
end
[[30,5],[0,5],[30,1],[-30,5]].each_with_index do |pair,index|
  bitmap.clear
  bitmap.set_pixel(6,3,Color.new(255,100,0,255))
  bitmap.radial_blur(pair[0],pair[1])
  pixels=[]
  8.times {|y|8.times {|x|c=bitmap.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
  rows << ["radial_impulse_#{index}",*pixels]
end
bitmap.fill_rect(0,0,8,8,Color.new(100,50,20,128))
bitmap.radial_blur(30,5)
rows << ['radial_uniform',*probe_pixels(bitmap)]
bitmap.fill_rect(0,0,8,8,Color.new(1,1,1,255))
bitmap.radial_blur(30,6)
rows << ['radial_low_uniform',*probe_pixels(bitmap)]
edge=Bitmap.new(16,16)
[[90,9],[120,9]].each_with_index do |pair,index|
  edge.clear
  edge.set_pixel(0,0,Color.new(255,0,0,255))
  edge.set_pixel(15,15,Color.new(0,255,0,128))
  edge.radial_blur(pair[0],pair[1])
  pixels=[]
  16.times {|y|16.times {|x|c=edge.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
  rows << ["radial_edge_#{index}",*pixels]
end
edge.dispose
rotation=Bitmap.new(16,16)
16.times {|y|16.times {|x|rotation.set_pixel(x,y,Color.new(x*15,y*15,(x+y)*7,128+(x+y)*3))}}
rotation.radial_blur(90,9)
pixels=[]
16.times {|y|16.times {|x|c=rotation.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
rows << ['radial_coordinate_grid',*pixels]
rotation.dispose
blurred=Bitmap.new(8,8)
blurred.set_pixel(3,3,Color.new(255,100,20,128))
blurred.blur
pixels=[]
8.times {|y|8.times {|x|c=blurred.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
rows << ['blur_impulse',*pixels]
blurred.dispose
scale_source=Bitmap.new(4,4)
4.times {|y|4.times {|x|scale_source.set_pixel(x,y,Color.new(x*60,y*60,0,255))}}
scale_dest=Bitmap.new(6,6)
scale_dest.stretch_blt(scale_dest.rect,scale_source,scale_source.rect)
pixels=[]
6.times {|y|6.times {|x|c=scale_dest.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
rows << ['stretch_grid',*pixels]
wide=Bitmap.new(8,8)
wide.stretch_blt(wide.rect,scale_source,scale_source.rect)
rows << ['stretch_grid_double',*(0...8).map {|x|wide.get_pixel(x,0).red}]
shrunk=Bitmap.new(3,3)
shrunk.stretch_blt(shrunk.rect,scale_source,scale_source.rect)
rows << ['stretch_grid_shrink',*(0...3).map {|x|shrunk.get_pixel(x,0).red}]
shrunk.dispose
wide.dispose
scale_dest.dispose
scale_source.dispose
palette=Bitmap.new(8,8)
[0,1,60,90,120,180,360].each do |angle|
  8.times do |y|
    8.times do |x|
      palette.set_pixel(x,y,Color.new(x*32,y*32,64,255))
    end
  end
  palette.hue_change(angle)
  pixels=[]
  8.times {|y|8.times {|x|c=palette.get_pixel(x,y);pixels << [c.red,c.green,c.blue,c.alpha].join(',')}}
  rows << ["hue_palette_#{angle}",*pixels]
end
palette.dispose
[false,true,nil].each_with_index do |vertical,index|
  bitmap.clear
  bitmap.gradient_fill_rect(0,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255),vertical)
  points=[[1,0],[0,1],[7,0],[0,7]].map {|x,y|bitmap.get_pixel(x,y).red}
  rows << ["gradient_flag_#{index}",*points]
end
source.dispose
bitmap.clear
bitmap.gradient_fill_rect(0,0,8,8,Color.new(0,0,0,255),Color.new(255,255,255,255))
rows << ['gradient_omitted',bitmap.get_pixel(1,0).red,bitmap.get_pixel(0,1).red]
overlap=Bitmap.new(8,8)
8.times {|x|overlap.fill_rect(x,0,1,8,Color.new(x*30,0,0,255))}
overlap.blt(2,0,overlap,Rect.new(0,0,6,8))
rows << ['self_blt',*(0...8).map {|x|overlap.get_pixel(x,0).red}]
overlap.dispose
bitmap.clear
bitmap.fill_rect(4,4,-3,-3,Color.new(255,0,0,255))
rows << ['negative_fill',bitmap.get_pixel(1,1).red,bitmap.get_pixel(3,3).red,bitmap.get_pixel(4,4).red]
[false,true,nil].each_with_index do |vertical,index|
  bitmap.clear
  bitmap.gradient_fill_rect(Rect.new(0,0,8,8),Color.new(0,0,0,255),Color.new(255,255,255,255),vertical)
  rows << ["gradient_rect_flag_#{index}",bitmap.get_pixel(1,0).red,bitmap.get_pixel(0,1).red]
end
bitmap.dispose
File.open(File.join(output,'bitmap_operations_reference.tsv'),'w'){|f|rows.each{|row|f.puts(row.join("\t"))}}
exit
