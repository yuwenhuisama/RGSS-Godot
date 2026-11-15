# Shared RGSS3 map-screen render fixture.
#
# Runs the installed stock scripts on both the original RGSS300 runtime and the
# Godot port: a real Spriteset_Map, Game_Screen, Sprite_Picture and
# Spriteset_Weather drive the real renderer. The only synthetic art is the
# picture bitmap injected into Cache (a 64x48 four-quadrant probe) and the
# backdrop sprite placed in viewport1 so screen tone/fade are visible. Weather
# particle bitmaps are the stock ones created by Spriteset_Weather.
#
# Output:
#   map_screen_render_reference.tsv  deterministic rows (hash-pinned)
#   map_screen_weather_reference.tsv RNG-dependent particle rows (invariants)
#   map_screen_*.rgba                544x416 raw RGBA captures
#
# The fixture never fakes Input, update or draw methods. It calls the stock
# update chain in Scene_Map order and lets the engine render each frame.

output = $rgss_compat_output || '.'
fmt = lambda { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }
sample = lambda do |snap, x, y|
  c = snap.get_pixel(x, y)
  [c.red.to_i, c.green.to_i, c.blue.to_i, c.alpha.to_i]
end
write_rgba = lambda do |snap, name|
  File.open(File.join(output, name), 'wb') do |file|
    snap.height.times do |y|
      bytes = []
      snap.width.times do |x|
        c = snap.get_pixel(x, y)
        bytes.concat([c.red.to_i, c.green.to_i, c.blue.to_i, c.alpha.to_i])
      end
      file.write(bytes.pack('C*'))
    end
  end
end
row = lambda { |file, values| file.puts(values.map { |value| fmt.call(value) }.join("\t")) }

saved = [$game_map, $game_player, $game_party, $game_timer, $data_system,
  $data_tilesets, $data_common_events, $data_animations, $game_message, $game_temp]
spriteset = nil
backdrop = nil
picture_bitmap = nil
cache = nil
original_key = nil
godot_key = nil
old_original = nil
old_godot = nil
det = nil
weather_rows = nil

begin
  # --- Fixture-only state, built through the original's own data classes. ---
  $data_system = RPG::System.new
  $data_system.opt_followers = false
  $data_system.opt_transparent = false
  $data_system.party_members = [1]
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].tileset_names = Array.new(9, '')
  $data_common_events = []
  $data_animations = [nil]
  $game_message = Game_Message.new
  $game_temp = Game_Temp.new
  $game_party = Game_Party.new
  $game_party.instance_variable_set(:@actors, [])
  $game_timer = Game_Timer.new
  $game_map = Game_Map.new
  map = RPG::Map.new(17, 13)
  map.tileset_id = 1
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@events, {})
  $game_map.instance_variable_set(:@common_events, [])
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.instance_variable_set(:@parallax_name, '')
  $game_map.instance_variable_set(:@parallax_x, 0)
  $game_map.instance_variable_set(:@parallax_y, 0)
  $game_map.instance_variable_set(:@scroll_rest, 0)
  $game_map.instance_variable_set(:@need_refresh, false)
  $game_player = Game_Player.new
  $game_player.moveto(0, 0)
  $game_player.refresh

  # The picture bitmap is fixture art; both engines resolve Cache by path.
  picture_bitmap = Bitmap.new(64, 48)
  picture_bitmap.fill_rect(0, 0, 32, 24, Color.new(220, 60, 40, 255))
  picture_bitmap.fill_rect(32, 0, 32, 24, Color.new(40, 200, 80, 255))
  picture_bitmap.fill_rect(0, 24, 32, 24, Color.new(40, 80, 220, 255))
  picture_bitmap.fill_rect(32, 24, 32, 24, Color.new(240, 220, 40, 255))
  picture_bitmap.fill_rect(2, 2, 4, 4, Color.new(255, 255, 255, 255))
  picture_bitmap.fill_rect(58, 42, 4, 4, Color.new(0, 0, 0, 255))
  cache = Cache.instance_variable_get(:@cache) || {}
  original_key = 'Graphics/Pictures/D06Probe'
  old_original = cache[original_key]
  cache[original_key] = picture_bitmap
  if DataManager.respond_to?(:__get_rtp_path__)
    godot_key = DataManager.__get_rtp_path__('Graphics/Pictures/') + 'D06Probe.png'
    old_godot = cache[godot_key]
    cache[godot_key] = picture_bitmap
  end
  Cache.instance_variable_set(:@cache, cache)

  spriteset = Spriteset_Map.new
  vp1 = spriteset.instance_variable_get(:@viewport1)
  vp2 = spriteset.instance_variable_get(:@viewport2)
  vp3 = spriteset.instance_variable_get(:@viewport3)
  vp1.z = 10000
  vp2.z = 10050
  vp3.z = 10100
  backdrop = Sprite.new(vp1)
  backdrop.bitmap = Bitmap.new(544, 416)
  backdrop.bitmap.fill_rect(backdrop.bitmap.rect, Color.new(40, 60, 90, 255))
  backdrop.z = -100

  screen = $game_map.screen
  picture_sprites = spriteset.instance_variable_get(:@picture_sprites)
  weather = spriteset.instance_variable_get(:@weather)

  det = File.open(File.join(output, 'map_screen_render_reference.tsv'), 'w')
  weather_rows = File.open(File.join(output, 'map_screen_weather_reference.tsv'), 'w')

  # The real Scene_Map update order: map/screen, player, timer, spriteset, frame.
  step = lambda do
    $game_map.update(true)
    $game_player.update
    $game_timer.update
    spriteset.update
    Graphics.update
  end

  5.times { step.call }

  # --- Picture origin / position / zoom / rotation / tone / erase. ---
  pic = screen.pictures[1]
  pic.show('D06Probe', 0, 100, 80, 100, 100, 255, 0)
  2.times { step.call }
  sprite = picture_sprites[1]
  snap = Graphics.snap_to_bitmap
  row.call(det, ['picture_plain', 0, 'sprite', sprite.x, sprite.y, sprite.z,
    sprite.ox, sprite.oy, sprite.zoom_x, sprite.zoom_y, sprite.opacity, sprite.angle])
  [[100, 80], [132, 80], [100, 104], [132, 104], [102, 82], [158, 122]].each do |x, y|
    r, g, b, a = sample.call(snap, x, y)
    row.call(det, ['picture_plain', 0, 'pixel', x, y, r, g, b, a])
  end
  write_rgba.call(snap, 'map_screen_picture_plain.rgba')
  snap.dispose
  det.flush

  # Control: stock Sprite_Picture assigns @picture.opacity, which Game_Picture
  # stores as Float. A plain Sprite is driven with Integer and Float opacity to
  # separate any Sprite#opacity= conversion defect from picture state logic.
  control = Sprite.new(vp2)
  control.bitmap = picture_bitmap
  control.x = 460
  control.y = 40
  control.z = 0
  control.opacity = 255
  step.call
  snap = Graphics.snap_to_bitmap
  row.call(det, ['opacity_control', 255, 'getter', control.opacity])
  r, g, b, a = sample.call(snap, 470, 50)
  row.call(det, ['opacity_control', 255, 'pixel', 470, 50, r, g, b, a])
  write_rgba.call(snap, 'map_screen_opacity_control_int.rgba')
  snap.dispose
  control.opacity = 255.0
  step.call
  snap = Graphics.snap_to_bitmap
  row.call(det, ['opacity_control', 255.0, 'getter', control.opacity])
  r, g, b, a = sample.call(snap, 470, 50)
  row.call(det, ['opacity_control', 255.0, 'pixel', 470, 50, r, g, b, a])
  write_rgba.call(snap, 'map_screen_opacity_control_float.rgba')
  snap.dispose
  control.dispose
  det.flush

  pic.show('D06Probe', 1, 300, 200, 100, 100, 255, 0)
  2.times { step.call }
  snap = Graphics.snap_to_bitmap
  row.call(det, ['picture_origin', 0, 'sprite', sprite.x, sprite.y, sprite.z,
    sprite.ox, sprite.oy, sprite.zoom_x, sprite.zoom_y, sprite.opacity, sprite.angle])
  [[268, 176], [300, 176], [268, 200], [300, 200], [270, 178], [326, 218]].each do |x, y|
    r, g, b, a = sample.call(snap, x, y)
    row.call(det, ['picture_origin', 0, 'pixel', x, y, r, g, b, a])
  end
  write_rgba.call(snap, 'map_screen_picture_origin.rgba')
  snap.dispose
  det.flush

  pic.show('D06Probe', 1, 400, 200, 100, 100, 255, 0)
  pic.rotate(180)
  step.call
  snap = Graphics.snap_to_bitmap
  row.call(det, ['picture_rotate', 0, 'sprite', sprite.x, sprite.y, sprite.z,
    sprite.ox, sprite.oy, sprite.zoom_x, sprite.zoom_y, sprite.opacity, sprite.angle])
  [[400, 200], [380, 200], [420, 200], [400, 180], [400, 220], [390, 190], [410, 210]].each do |x, y|
    r, g, b, a = sample.call(snap, x, y)
    row.call(det, ['picture_rotate', 0, 'pixel', x, y, r, g, b, a])
  end
  write_rgba.call(snap, 'map_screen_picture_rotate.rgba')
  snap.dispose
  det.flush

  pic.show('D06Probe', 0, 60, 300, 100, 100, 255, 0)
  step.call
  pic.move(1, 200, 320, 200, 200, 128, 0, 4)
  4.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['picture_move', frame, 'sprite', sprite.x, sprite.y, sprite.z,
      sprite.ox, sprite.oy, sprite.zoom_x, sprite.zoom_y, sprite.opacity, sprite.angle])
    r, g, b, a = sample.call(snap, 200, 320)
    row.call(det, ['picture_move', frame, 'pixel', 200, 320, r, g, b, a])
    write_rgba.call(snap, "map_screen_picture_move_#{frame}.rgba")
    snap.dispose
    det.flush
  end

  pic.show('D06Probe', 0, 100, 300, 100, 100, 255, 0)
  step.call
  pic.start_tone_change(Tone.new(80, -40, 60, 40), 3)
  3.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['picture_tone', frame, 'picture_tone', pic.tone.red, pic.tone.green,
      pic.tone.blue, pic.tone.gray])
    row.call(det, ['picture_tone', frame, 'sprite_tone', sprite.tone.red, sprite.tone.green,
      sprite.tone.blue, sprite.tone.gray])
    r, g, b, a = sample.call(snap, 110, 310)
    row.call(det, ['picture_tone', frame, 'pixel', 110, 310, r, g, b, a])
    write_rgba.call(snap, "map_screen_picture_tone_#{frame}.rgba")
    snap.dispose
    det.flush
  end

  pic.erase
  step.call
  snap = Graphics.snap_to_bitmap
  row.call(det, ['picture_erase', 0, 'picture_name', pic.name])
  row.call(det, ['picture_erase', 0, 'bitmap_size', sprite.bitmap.width, sprite.bitmap.height])
  r, g, b, a = sample.call(snap, 110, 310)
  row.call(det, ['picture_erase', 0, 'pixel', 110, 310, r, g, b, a])
  write_rgba.call(snap, 'map_screen_picture_erase.rgba')
  snap.dispose
  det.flush

  # --- Screen tone over viewport1 (backdrop is fixture-owned). ---
  screen.start_tone_change(Tone.new(80, -40, 20, 60), 4)
  4.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['screen_tone', frame, 'screen_tone', screen.tone.red, screen.tone.green,
      screen.tone.blue, screen.tone.gray])
    row.call(det, ['screen_tone', frame, 'viewport_tone', vp1.tone.red, vp1.tone.green,
      vp1.tone.blue, vp1.tone.gray])
    r, g, b, a = sample.call(snap, 50, 50)
    row.call(det, ['screen_tone', frame, 'pixel', 50, 50, r, g, b, a])
    write_rgba.call(snap, "map_screen_screen_tone_#{frame}.rgba")
    snap.dispose
    det.flush
  end
  screen.start_tone_change(Tone.new(0, 0, 0, 0), 0)
  step.call

  # --- Screen flash over viewport2 (sample a real picture in that viewport). ---
  pic.show('D06Probe', 0, 200, 100, 100, 100, 255, 0)
  step.call
  screen.start_flash(Color.new(200, 80, 40, 160), 4)
  4.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['screen_flash', frame, 'flash_alpha', screen.flash_color.alpha])
    row.call(det, ['screen_flash', frame, 'viewport_color', vp2.color.red, vp2.color.green,
      vp2.color.blue, vp2.color.alpha])
    r, g, b, a = sample.call(snap, 210, 110)
    row.call(det, ['screen_flash', frame, 'pixel', 210, 110, r, g, b, a])
    r, g, b, a = sample.call(snap, 300, 300)
    row.call(det, ['screen_flash', frame, 'backdrop_pixel', 300, 300, r, g, b, a])
    write_rgba.call(snap, "map_screen_screen_flash_#{frame}.rgba")
    snap.dispose
    det.flush
  end
  screen.start_flash(Color.new(0, 0, 0, 0), 0)
  step.call
  pic.erase
  step.call

  # --- Screen fade over viewport3. ---
  screen.start_fadeout(4)
  4.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['screen_fadeout', frame, 'brightness', screen.brightness])
    row.call(det, ['screen_fadeout', frame, 'viewport_color', vp3.color.red, vp3.color.green,
      vp3.color.blue, vp3.color.alpha])
    r, g, b, a = sample.call(snap, 50, 50)
    row.call(det, ['screen_fadeout', frame, 'pixel', 50, 50, r, g, b, a])
    write_rgba.call(snap, "map_screen_screen_fadeout_#{frame}.rgba")
    snap.dispose
    det.flush
  end
  screen.start_fadein(4)
  4.times do |frame|
    step.call
    snap = Graphics.snap_to_bitmap
    row.call(det, ['screen_fadein', frame, 'brightness', screen.brightness])
    row.call(det, ['screen_fadein', frame, 'viewport_color', vp3.color.red, vp3.color.green,
      vp3.color.blue, vp3.color.alpha])
    r, g, b, a = sample.call(snap, 50, 50)
    row.call(det, ['screen_fadein', frame, 'pixel', 50, 50, r, g, b, a])
    write_rgba.call(snap, "map_screen_screen_fadein_#{frame}.rgba")
    snap.dispose
    det.flush
  end

  # --- Weather: stock Spriteset_Weather bitmaps and update chain. ---
  # Particle positions use Kernel#rand, whose sequence differs between the
  # original and mruby. State/motion/bitmap rows are deterministic; particle
  # coordinates and opacities are recorded separately as invariants.
  bitmap_probe = lambda do |name, bitmap, samples|
    total = 0
    bitmap.height.times do |y|
      bitmap.width.times do |x|
        total += bitmap.get_pixel(x, y).alpha.to_i
      end
    end
    row.call(det, ['weather_bitmap', name, 'size', bitmap.width, bitmap.height])
    row.call(det, ['weather_bitmap', name, 'alpha_sum', total])
    samples.each do |x, y|
      r, g, b, a = sample.call(bitmap, x, y)
      row.call(det, ['weather_bitmap', name, 'pixel', x, y, r, g, b, a])
    end
    det.flush
  end
  bitmap_probe.call('rain', weather.instance_variable_get(:@rain_bitmap),
    [[6, 0], [5, 6], [0, 36], [3, 3], [6, 6]])
  bitmap_probe.call('storm', weather.instance_variable_get(:@storm_bitmap),
    [[33, 0], [32, 0], [31, 0], [0, 62], [10, 10]])
  bitmap_probe.call('snow', weather.instance_variable_get(:@snow_bitmap),
    [[0, 0], [0, 1], [1, 0], [1, 2], [2, 1], [5, 5]])

  weather_phase = lambda do |name, type, power|
    screen.change_weather(type, power, 0)
    2.times { step.call }
    sprites = weather.instance_variable_get(:@sprites)
    row.call(det, ['weather_state', name, 'type', weather.type])
    row.call(det, ['weather_state', name, 'power', weather.power])
    row.call(det, ['weather_state', name, 'sprite_max', weather.sprite_max])
    row.call(det, ['weather_state', name, 'sprite_count', sprites.size])
    row.call(det, ['weather_state', name, 'dimness', weather.dimness])
    row.call(det, ['weather_state', name, 'viewport_tone', vp2.tone.red, vp2.tone.green,
      vp2.tone.blue, vp2.tone.gray])
    first = sprites[0]
    before_x = first.x
    before_y = first.y
    before_opacity = first.opacity
    step.call
    row.call(det, ['weather_state', name, 'motion', first.x - before_x, first.y - before_y,
      first.opacity - before_opacity])
    row.call(weather_rows, ['weather_particle', name, 'first', first.x, first.y, first.opacity])
    opacities = []
    sprites.each { |sprite| opacities << sprite.opacity }
    row.call(weather_rows, ['weather_particle', name, 'opacity_min', opacities.min])
    row.call(weather_rows, ['weather_particle', name, 'opacity_max', opacities.max])
    snap = Graphics.snap_to_bitmap
    write_rgba.call(snap, "map_screen_weather_#{name}.rgba")
    snap.dispose
    det.flush
    weather_rows.flush
  end

  weather_phase.call('rain', :rain, 6)
  weather_phase.call('storm', :storm, 9)
  weather_phase.call('snow', :snow, 3)
  screen.change_weather(:none, 0, 0)
  2.times { step.call }
  row.call(det, ['weather_state', 'clear', 'type', weather.type])
  row.call(det, ['weather_state', 'clear', 'power', weather.power])
  row.call(det, ['weather_state', 'clear', 'sprite_max', weather.sprite_max])
  row.call(det, ['weather_state', 'clear', 'sprite_count',
    weather.instance_variable_get(:@sprites).size])
  row.call(det, ['weather_state', 'clear', 'dimness', weather.dimness])
  row.call(det, ['weather_state', 'clear', 'viewport_tone', vp2.tone.red, vp2.tone.green,
    vp2.tone.blue, vp2.tone.gray])
  snap = Graphics.snap_to_bitmap
  write_rgba.call(snap, 'map_screen_weather_clear.rgba')
  snap.dispose
  det.flush
rescue Exception => error
  File.open(File.join(output, 'map_screen_render_error.txt'), 'w') do |file|
    file.puts(error.class.to_s, error.message, error.backtrace)
  end
  raise if $rgss_compat_output
ensure
  det.close if det && !det.closed?
  weather_rows.close if weather_rows && !weather_rows.closed?
  begin
    backdrop.dispose if backdrop && !backdrop.disposed?
  rescue Exception
  end
  begin
    spriteset.dispose if spriteset
  rescue Exception
  end
  begin
    picture_bitmap.dispose if picture_bitmap && !picture_bitmap.disposed?
  rescue Exception
  end
  if cache
    if original_key
      old_original ? cache[original_key] = old_original : cache.delete(original_key)
    end
    if godot_key
      old_godot ? cache[godot_key] = old_godot : cache.delete(godot_key)
    end
  end
  $game_map, $game_player, $game_party, $game_timer, $data_system,
    $data_tilesets, $data_common_events, $data_animations, $game_message, $game_temp = saved
end
exit unless $rgss_compat_output
