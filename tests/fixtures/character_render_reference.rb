output = $rgss_compat_output || '.'
saved = [$game_map, $data_system, $data_tilesets]
sprites = []
bitmaps = []
begin
  $data_system = RPG::System.new
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[0] = 0x10
  $data_tilesets[1].flags[1] = 0x40
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  map.tileset_id = 1
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  Cache.instance_variable_set(:@cache, {}) unless Cache.instance_variable_get(:@cache)
  atlas = Bitmap.new(96, 128)
  bitmaps << atlas
  4.times do |direction|
    3.times do |pose|
      x = pose * 32
      y = direction * 32
      atlas.fill_rect(x + 11, y + 2, 10, 8, Color.new(230, 190, 120))
      atlas.fill_rect(x + 8, y + 10, 16, 13, Color.new(40 + direction * 50, 80 + pose * 60, 220))
      atlas.fill_rect(x + 8 + pose * 2, y + 23, 5, 8 - pose, Color.new(180, 60, 40))
      atlas.fill_rect(x + 20 - pose * 2, y + 23, 5, 6 + pose, Color.new(80, 220, 60))
    end
  end
  key = 'Graphics/Characters/$D03Probe'
  if DataManager.respond_to?(:__get_rtp_path__)
    key = DataManager.__get_rtp_path__('Graphics/Characters/') + '$D03Probe.png'
  end
  cache = Cache.instance_variable_get(:@cache)
  old = cache[key]
  cache[key] = atlas
  viewport = Viewport.new(0, 0, 544, 416)
  viewport.z = 10000
  background = Bitmap.new(544, 416)
  background.fill_rect(background.rect, Color.new(30, 35, 45))
  bitmaps << background
  backdrop = Sprite.new(viewport)
  backdrop.bitmap = background
  backdrop.z = -100
  sprites << backdrop
  characters = []
  [2, 4, 6, 8].each_with_index do |direction, index|
    character = Game_Character.new
    character.set_graphic('$D03Probe', 0)
    character.moveto(3 + index * 3, 7)
    character.set_direction(direction)
    character.instance_variable_set(:@step_anime, true)
    characters << character
    sprites << Sprite_Character.new(viewport, character)
  end
  jumper = Game_Character.new
  jumper.set_graphic('$D03Probe', 0)
  jumper.moveto(6, 10)
  jumper.jump(2, 0)
  characters << jumper
  sprites << Sprite_Character.new(viewport, jumper)
  File.open(File.join(output, 'character_render_reference.tsv'), 'w') do |rows|
    33.times do |frame|
      if [0, 4, 8, 12, 16, 24, 32].include?(frame)
        2.times { Graphics.update }
        image = Graphics.snap_to_bitmap
        File.open(File.join(output, "character_frame_#{frame}.rgba"), 'wb') do |file|
          image.height.times do |y|
            bytes = []
            image.width.times do |x|
              color = image.get_pixel(x, y)
              bytes.concat([color.red.to_i, color.green.to_i, color.blue.to_i, color.alpha.to_i])
            end
            file.write(bytes.pack('C*'))
          end
        end
        sprites[1..-1].each_with_index do |sprite, index|
          rows.puts([frame, index, sprite.x, sprite.y, sprite.z,
            sprite.src_rect.x, sprite.src_rect.y, sprite.src_rect.width,
            sprite.src_rect.height, sprite.bush_depth].join("\t"))
        end
        rows.flush
        image.dispose
      end
      characters.each { |character| character.update }
      sprites[1..-1].each { |sprite| sprite.update }
    end
  end
rescue Exception => error
  File.open(File.join(output, 'character_render_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  sprites.each { |sprite| sprite.dispose unless sprite.disposed? }
  viewport.dispose if viewport && !viewport.disposed?
  cache[key] = old if cache && key
  bitmaps.each { |bitmap| bitmap.dispose unless bitmap.disposed? }
  $game_map, $data_system, $data_tilesets = saved
end
exit unless $rgss_compat_output
