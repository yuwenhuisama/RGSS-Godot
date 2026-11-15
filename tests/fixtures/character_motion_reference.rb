output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $data_system, $data_tilesets]
begin
  $data_system = RPG::System.new
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[0] = 0x10
  $data_tilesets[1].flags[1] = 0
  $data_tilesets[1].flags[2] = 0x40
  $data_tilesets[1].flags[3] = 0x20
  $data_tilesets[1].flags[4] = 0x0f
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  map.tileset_id = 1
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_party = Game_Party.new
  $game_player = Game_Player.new
  $game_player.moveto(10, 10)
  File.open(File.join(output, 'character_motion_reference.tsv'), 'w') do |file|
    record = proc do |label, frame, character|
      values = [label, frame, character.x, character.y,
        sprintf('%.9f', character.real_x), sprintf('%.9f', character.real_y),
        sprintf('%.9f', character.screen_x), sprintf('%.9f', character.screen_y),
        character.direction, character.pattern, character.jump_height,
        character.bush_depth, character.moving?, character.jumping?]
      file.puts(values.join("\t"))
      file.flush
    end
    (1..6).each do |speed|
      [2, 4, 6, 8].each do |direction|
        character = Game_Character.new
        character.moveto(8, 8)
        character.instance_variable_set(:@move_speed, speed)
        character.move_straight(direction)
        (0..130).each do |frame|
          record.call("walk-#{speed}-#{direction}", frame, character)
          break if character.stopping? && frame > 0
          character.update
        end
      end
    end
    [[4, 2], [4, 8], [6, 2], [6, 8]].each do |directions|
      character = Game_Character.new
      character.moveto(8, 8)
      character.move_diagonal(*directions)
      18.times { |frame| record.call("diagonal-#{directions.join('-')}", frame, character); character.update }
    end
    [[0, 0], [1, 0], [-2, 3], [5, -4]].each do |offset|
      character = Game_Character.new
      character.moveto(8, 8)
      character.jump(*offset)
      40.times { |frame| record.call("jump-#{offset.join('-')}", frame, character); character.update }
    end
    [false, true].each do |step|
      character = Game_Character.new
      character.moveto(8, 8)
      character.instance_variable_set(:@step_anime, step)
      40.times { |frame| record.call("idle-#{step}", frame, character); character.update }
    end
    [2, 3, 4].each do |tile|
      map.data[9, 8, 0] = tile
      character = Game_Character.new
      character.moveto(8, 8)
      character.move_straight(6)
      18.times { |frame| record.call("terrain-#{tile}", frame, character); character.update }
      map.data[9, 8, 0] = 1
    end
    4.times do |mode|
      map.scroll_type = mode
      character = Game_Character.new
      character.moveto(23, 19)
      character.move_diagonal(6, 2)
      18.times { |frame| record.call("loop-#{mode}", frame, character); character.update }
    end
    map.scroll_type = 0
    [:boat, :ship, :airship].each do |type|
      vehicle = Game_Vehicle.new(type)
      vehicle.set_location(1, 8, 8)
      vehicle.get_on
      35.times do |frame|
        record.call("vehicle-on-#{type}", frame, vehicle)
        file.puts([type, frame, vehicle.speed, vehicle.altitude, vehicle.driving,
          vehicle.movable?, vehicle.screen_z, vehicle.transparent].join("\t"))
        vehicle.update
      end
      vehicle.get_off
      35.times do |frame|
        record.call("vehicle-off-#{type}", frame, vehicle)
        file.puts([type, frame, vehicle.speed, vehicle.altitude, vehicle.driving,
          vehicle.movable?, vehicle.screen_z, vehicle.transparent].join("\t"))
        vehicle.update
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'character_motion_error.txt'), 'w') do |file|
    file.puts(error.class.to_s, error.message, error.backtrace)
  end
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $data_system, $data_tilesets = saved
end
exit unless $rgss_compat_output
