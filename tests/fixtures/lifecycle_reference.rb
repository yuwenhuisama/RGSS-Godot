output=$rgss_compat_output || '.'
rows=[]
b=Bitmap.new(32,32)
s=Sprite.new
s.bitmap=b
rows << ['bitmap_ref',s.bitmap.equal?(b)]
rect=s.src_rect
rect.x=7
rows << ['src_rect_ref',s.src_rect.equal?(rect),s.src_rect.x]
tone=s.tone
tone.red=80
rows << ['tone_ref',s.tone.equal?(tone),s.tone.red]
color=s.color
color.red=90
rows << ['color_ref',s.color.equal?(color),s.color.red]
s.dispose
rows << ['sprite_disposed',s.disposed?]
begin
  s.x
  rows << ['sprite_after_dispose','no_error']
rescue Exception=>error
  rows << ['sprite_after_dispose',error.class.to_s]
end
b.dispose
begin
  b.get_pixel(0,0)
  rows << ['bitmap_after_dispose','no_error']
rescue Exception=>error
  rows << ['bitmap_after_dispose',error.class.to_s]
end
v=Viewport.new(0,0,32,32)
plane=Plane.new(v)
plane.bitmap=Bitmap.new(16,16)
rows << ['plane_refs',plane.viewport.equal?(v),plane.bitmap.equal?(plane.bitmap),plane.color.equal?(plane.color),plane.tone.equal?(plane.tone)]
w=Window.new(0,0,32,32)
w.viewport=v
rows << ['window_refs',w.viewport.equal?(v),w.contents.equal?(w.contents),w.cursor_rect.equal?(w.cursor_rect),w.tone.equal?(w.tone),w.windowskin.nil?]
rows << ['viewport_refs',v.rect.equal?(v.rect),v.color.equal?(v.color),v.tone.equal?(v.tone)]
tm=Tilemap.new(v)
rows << ['tilemap_ref',tm.viewport.equal?(v)]
[plane,w,v,tm].each do |resource|
  resource.dispose
  resource.dispose
  begin
    resource.visible
    rows << [resource.class.to_s,'no_error']
  rescue Exception=>error
    rows << [resource.class.to_s,error.class.to_s]
  end
end
File.open(File.join(output,'lifecycle_reference.tsv'),'w'){|f|rows.each{|row|f.puts(row.join("\t"))}}
exit
