# Same deterministic scene on the installed original and the Godot port.
output = $rgss_compat_output || '.'
background = Bitmap.new(544, 416)
background.fill_rect(0, 0, 272, 416, Color.new(20, 150, 40))
background.fill_rect(272, 0, 272, 416, Color.new(170, 30, 50))
sprite = Sprite.new
sprite.bitmap = background
skin = Bitmap.new(128, 128)
skin.fill_rect(0, 0, 64, 128, Color.new(20, 40, 180))
window = Window.new(80, 80, 320, 240)
window.windowskin = skin
window.back_opacity = 128
8.times { Graphics.update }
snapshot = Graphics.snap_to_bitmap
File.open(File.join(output, 'render_reference.rgba'), 'wb') do |file|
  snapshot.height.times do |y|
    row = []
    snapshot.width.times do |x|
      c = snapshot.get_pixel(x, y)
      row.concat([c.red.to_i, c.green.to_i, c.blue.to_i, c.alpha.to_i])
    end
    file.write(row.pack('C*'))
  end
end
File.open(File.join(output, 'render_reference_size.txt'), 'w') { |f| f.write([snapshot.width, snapshot.height].join(',')) }
snapshot.dispose
window.dispose
skin.dispose
sprite.dispose
background.dispose
exit
