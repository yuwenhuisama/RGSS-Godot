output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_variables, $data_system, $data_tilesets]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(30, 'variable')
  $data_tilesets = [nil, RPG::Tileset.new, RPG::Tileset.new]
  $data_tilesets[1].id = 1
  $data_tilesets[2].id = 2
  $data_tilesets[1].flags[0] = 0x10
  $data_tilesets[1].flags[1] = 3 << 12
  $game_map = Game_Map.new
  data = RPG::Map.new(24, 20)
  data.tileset_id = 1
  data.data[5, 6, 0] = 1
  data.data[5, 6, 1] = 2
  data.data[5, 6, 2] = 3
  data.data[5, 6, 3] = 9 << 8
  $game_map.instance_variable_set(:@map, data)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.instance_variable_set(:@common_events, [])
  $game_message = Game_Message.new
  $game_variables = Game_Variables.new
  $game_variables[20] = 5
  $game_variables[21] = 6
  $game_variables[22] = 1
  cases = [
    ['name-hide', 281, [1]], ['name-show', 281, [0]],
    ['battleback', 283, ['Grass', 'Forest']],
    ['parallax-loop', 284, ['Sky', true, true, 3, -2]],
    ['parallax-static', 284, ['Cloud', false, false, 0, 0]],
    ['boat-position', 202, [0, 0, 1, 5, 6]],
    ['ship-variable', 202, [1, 1, 22, 20, 21]],
    ['airship-other-map', 202, [2, 0, 2, 8, 9]]
  ]
  6.times do |kind|
    cases << ["location-direct-#{kind}", 285, [kind + 1, kind, 0, 5, 6]]
    cases << ["location-variable-#{kind}", 285, [kind + 7, kind, 1, 20, 21]]
  end
  cases << ['tileset', 282, [2]]
  File.open(File.join(output, 'event_map_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(code, 0, parameters), RPG::EventCommand.new])
      count = 0
      while interpreter.running?
        raise "map event hung: #{name}" if count >= 10
        interpreter.update
        count += 1
      end
      values = [name, count, $game_map.name_display, $game_map.tileset.id,
        $game_map.battleback1_name, $game_map.battleback2_name, $game_map.parallax_name]
      $game_map.vehicles.each do |vehicle|
        values.concat([vehicle.x, vehicle.y, vehicle.transparent])
      end
      values.concat((1..12).map { |id| $game_variables[id] })
      file.puts(values.join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_map_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_variables, $data_system, $data_tilesets = saved
end
exit unless $rgss_compat_output
