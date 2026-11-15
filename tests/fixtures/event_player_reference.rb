output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_message, $game_system,
  $game_temp, $data_system, $data_tilesets, $game_variables]
begin
  $data_system = RPG::System.new
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[1] = 0
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_party = Game_Party.new
  $game_message = Game_Message.new
  $game_system = Game_System.new
  $game_temp = Game_Temp.new
  $data_system.variables = [nil, 'result']
  $game_variables = Game_Variables.new
  $game_player = Game_Player.new
  $game_player.moveto(10, 10)
  $game_player.set_direction(6)
  $game_map.boat.set_location(1, 11, 10)
  cases = [['encounter-disable', 136, [0]], ['encounter-enable', 136, [1]],
    ['vehicle-board', 206, []], ['boat-condition', 111, [13, 0]],
    ['ship-condition', 111, [13, 1]], ['airship-condition', 111, [13, 2]],
    ['vehicle-dismount', 206, []], ['boat-after-dismount', 111, [13, 0]]]
  File.open(File.join(output, 'event_player_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      list = [RPG::EventCommand.new(code, 0, parameters)]
      if code == 111
        list.concat([RPG::EventCommand.new(122, 1, [1, 1, 0, 0, 1]),
          RPG::EventCommand.new(411, 0, []), RPG::EventCommand.new(122, 1, [1, 1, 0, 0, 0]),
          RPG::EventCommand.new(412, 0, [])])
      end
      list << RPG::EventCommand.new
      interpreter.setup(list)
      25.times do |frame|
        interpreter.update
        values = [name, frame, interpreter.running?, $game_system.encounter_disabled,
          $game_player.x, $game_player.y, $game_player.real_x, $game_player.real_y,
          $game_player.in_boat?, $game_player.transparent, $game_player.move_speed,
          $game_map.boat.driving, $game_player.instance_variable_get(:@vehicle_getting_on),
          $game_player.instance_variable_get(:@vehicle_getting_off), $game_variables[1]]
        file.puts(values.map { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }.join("\t"))
        file.flush
        $game_player.update_move if $game_player.moving?
        $game_player.followers.update
        $game_player.update_vehicle
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_player_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_message, $game_system,
    $game_temp, $data_system, $data_tilesets, $game_variables = saved
end
exit unless $rgss_compat_output
