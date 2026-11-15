output = $rgss_compat_output || '.'
viewport = Viewport.new
weather = Spriteset_Weather.new(viewport)
weather.type = :storm
weather.power = 1
weather.update
sprite = weather.instance_variable_get(:@sprites)[0]
sprite.x = -100
sprite.y = -200
sprite.opacity = 160
File.open(File.join(output, 'weather_bounds_reference.tsv'), 'w') do |file|
  8.times { weather.update }
  file.puts ['storm-edge', sprite.x, sprite.y, sprite.opacity].join("\t")
  weather.type = :snow
  file.puts ['snow-before-update', sprite.x, sprite.y, sprite.opacity].join("\t")
  weather.update
  file.puts ['snow-after-rebirth', sprite.opacity >= 160, sprite.x >= -100].join("\t")
end
weather.dispose
viewport.dispose
exit unless $weather_bounds_host
