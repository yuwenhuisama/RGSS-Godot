bitmap=Bitmap.new(3,3)
source=Bitmap.new(32,32)
32.times do |y|
  32.times do |x|
    source.set_pixel(x,y,Color.new(20+[x,y,31-x,31-y].min*12,40+x*5,60+y*5,32+x*7))
  end
end
bitmap.blt(0,0,source,Rect.new(0,0,4,4))
bitmap.blt(-1,0,source,Rect.new(28,0,4,4))
bitmap.blt(0,-1,source,Rect.new(0,28,4,4))
bitmap.blt(-1,-1,source,Rect.new(28,28,4,4))
File.open(TestPaths.output('cursor_cache_reference.tsv'),'w') do |file|
  3.times do |y|
    3.times do |x|
      c=bitmap.get_pixel(x,y)
      file.puts([x,y,c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i].join("\t"))
    end
  end
end
bitmap.dispose;source.dispose
exit
