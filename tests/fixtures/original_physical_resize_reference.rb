# Original RGSS300 physical resize reference.
#
# Run only through tools/prepare_original_fixture.rb in an isolated project
# copy. The fixture draws the same 640x480 logical surface as the Godot
# physical-resize runner: four 4-pixel coloured borders plus an 8x8 one-pixel
# checkerboard at (300,220). It keeps presenting frames until the host writes
# stop.signal, then exits 0 and writes its own logical evidence.
#
# An optional logical_size.txt ("WIDTH HEIGHT") in the working directory makes
# the fixture request that logical size instead of 640x480; the physical
# harness uses it to see whether fullscreen follows the logical size.
output = '.'
begin
  requested = [640, 480]
  if File.exist?('logical_size.txt')
    requested = File.read('logical_size.txt').split.map(&:to_i)
    requested = [640, 480] unless requested.length == 2
  end
  Graphics.resize_screen(*requested)
  width = Graphics.width
  height = Graphics.height
  bitmap = Bitmap.new(width, height)
  bitmap.fill_rect(bitmap.rect, Color.new(20, 80, 120))
  bitmap.fill_rect(0, 0, width, 4, Color.new(255, 0, 0))
  bitmap.fill_rect(width - 4, 0, 4, height, Color.new(0, 255, 0))
  bitmap.fill_rect(0, height - 4, width, 4, Color.new(0, 0, 255))
  bitmap.fill_rect(0, 0, 4, height, Color.new(255, 255, 0))
  8.times do |y|
    8.times do |x|
      bitmap.set_pixel(300 + x, 220 + y,
                       (x + y) % 2 == 0 ? Color.new(255, 255, 255) : Color.new(0, 0, 0))
    end
  end
  sprite = Sprite.new
  sprite.bitmap = bitmap
  Graphics.update

  snapshot = Graphics.snap_to_bitmap
  rows = []
  rows << ['logical', Graphics.width, Graphics.height, snapshot.width, snapshot.height]
  [[0, 0], [width - 1, 0], [0, height - 1], [width - 1, height - 1],
   [2, height / 2], [width - 3, height / 2], [width / 2, 2], [width / 2, height - 3]].each do |x, y|
    next unless x >= 0 && y >= 0 && x < snapshot.width && y < snapshot.height
    color = snapshot.get_pixel(x, y)
    rows << ['border', x, y, color.red, color.green, color.blue, color.alpha]
  end
  [[300, 220], [301, 220], [300, 221], [307, 227]].each do |x, y|
    next unless x < snapshot.width && y < snapshot.height
    color = snapshot.get_pixel(x, y)
    rows << ['checker', x, y, color.red, color.green, color.blue, color.alpha]
  end
  snapshot.dispose
  File.open(File.join(output, 'physical_resize_reference.tsv'), 'w') do |file|
    rows.each { |row| file.puts(row.join("\t")) }
  end
  File.open(File.join(output, 'ready.txt'), 'w') { |file| file.write("ready\n") }

  frames = 0
  snapshots = 0
  loop do
    Graphics.update
    frames += 1
    if File.exist?(File.join(output, 'snapshot.request'))
      File.delete(File.join(output, 'snapshot.request'))
      snapshots += 1
      File.open(File.join(output, "snapshot-#{snapshots}.before"), 'w') { |file| file.write("before\n") }
      shot = Graphics.snap_to_bitmap
      File.open(File.join(output, "snapshot-#{snapshots}.after"), 'w') { |file| file.write("after\n") }
      raw = []
      shot.height.times do |y|
        shot.width.times do |x|
          color = shot.get_pixel(x, y)
          raw << color.red.to_i << color.green.to_i << color.blue.to_i << color.alpha.to_i
        end
      end
      File.open(File.join(output, "snapshot-#{snapshots}.rgba"), 'wb') do |file|
        file.write(raw.pack('C*'))
      end
      probes = []
      [[0, 0], [shot.width - 1, 0], [0, shot.height - 1], [shot.width - 1, shot.height - 1],
       [2, shot.height / 2], [shot.width - 3, shot.height / 2],
       [shot.width / 2, 2], [shot.width / 2, shot.height - 3]].each do |x, y|
        color = shot.get_pixel(x, y)
        probes << [x, y, color.red, color.green, color.blue, color.alpha]
      end
      File.open(File.join(output, "snapshot-#{snapshots}.tsv"), 'w') do |file|
        file.puts(['size', shot.width, shot.height].join("\t"))
        probes.each { |row| file.puts(row.join("\t")) }
      end
      shot.dispose
    end
    break if File.exist?(File.join(output, 'stop.signal'))
    break if frames >= 18000
  end

  File.open(File.join(output, 'physical_resize_run.tsv'), 'w') do |file|
    file.puts(['frames', frames].join("\t"))
    file.puts(['final_logical', Graphics.width, Graphics.height].join("\t"))
    file.puts(['frame_count', Graphics.frame_count].join("\t"))
  end
  sprite.dispose
  bitmap.dispose
  exit 0
rescue SystemExit
  raise
rescue Exception => error
  File.open(File.join(output, 'physical_resize_error.txt'), 'w') do |file|
    file.write("#{error.class}: #{error.message}\n")
    file.write(error.backtrace.join("\n"))
  end
  exit 1
end
