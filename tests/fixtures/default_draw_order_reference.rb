output = $rgss_compat_output || '.'
background = Sprite.new
background.bitmap = Bitmap.new(64,64)
background.bitmap.fill_rect(background.bitmap.rect,Color.new(255,0,0))
viewport = Viewport.new(0,0,64,64)
foreground = Sprite.new(viewport)
foreground.bitmap = Bitmap.new(64,64)
foreground.bitmap.fill_rect(foreground.bitmap.rect,Color.new(0,255,0))
File.open(File.join(output,'default_draw_order_reference.tsv'),'w') do |file|
  file.puts ['default-z',background.z,foreground.z,viewport.z].join("\t")
  2.times { Graphics.update }
  image = Graphics.snap_to_bitmap
  pixel = image.get_pixel(20,20)
  file.puts ['pixel',pixel.red.to_i,pixel.green.to_i,pixel.blue.to_i].join("\t")
  image.dispose
end
foreground.bitmap.dispose;foreground.dispose;viewport.dispose
background.bitmap.dispose;background.dispose
exit unless $default_draw_order_host
