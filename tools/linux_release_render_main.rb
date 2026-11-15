['tone', 'rect', 'color', 'font', 'graphics', 'sprite', 'bitmap', 'viewport'].each { |name| require name }
main_fiber = Fiber.new do
bitmap = Bitmap.new(544, 416)
bitmap.fill_rect(0, 0, 544, 416, Color.new(24, 32, 48))
bitmap.fill_rect(32, 48, 128, 128, Color.new(240, 48, 48))
bitmap.fill_rect(208, 48, 128, 128, Color.new(48, 224, 80))
bitmap.fill_rect(384, 48, 128, 128, Color.new(48, 96, 240))
bitmap.font.size = 24
bitmap.draw_text(32, 208, 480, 40, 'Linux Release / RGSS-Godot', 1)
bitmap.draw_text(32, 264, 480, 40, '544 x 416 - rendered output', 1)
sprite = Sprite.new
sprite.bitmap = bitmap
puts 'LINUX_RELEASE_RENDER_READY'
loop { Graphics.update }
end
Unity.register_update_fiber(main_fiber)
