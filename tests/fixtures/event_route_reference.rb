output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_system, $game_message,
  $game_switches, $game_variables, $data_system, $data_tilesets]
begin
  $data_system = RPG::System.new
  $data_system.switches = [nil, 'route']
  $data_system.variables = [nil, 'route']
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[1] = 0
  $game_map = Game_Map.new
  map = RPG::Map.new(30, 25)
  25.times { |y| 30.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.instance_variable_set(:@common_events, [])
  $game_party = Game_Party.new
  $game_system = Game_System.new
  $game_message = Game_Message.new
  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_player = Game_Player.new
  $game_player.moveto(15, 12)
  arguments = {14 => [2, -1], 15 => [3], 27 => [1], 28 => [1],
    29 => [5], 30 => [6], 41 => ['Route', 2], 42 => [128], 43 => [2],
    44 => [RPG::SE.new], 45 => ['$game_variables[1] = 42']}
  File.open(File.join(output, 'event_route_reference.tsv'), 'w') do |file|
    (1..45).each do |code|
      next if [9, 23, 24].include?(code) # random movement/direction are checked below
      $game_switches[1] = false
      $game_variables[1] = 0
      event_data = RPG::Event.new(10, 10)
      event_data.id = 1
      event_data.pages[0].through = true
      character = Game_Event.new(1, event_data)
      character.moveto(10, 10)
      character.instance_variable_set(:@through, true)
      $game_map.instance_variable_set(:@events, {1 => character})
      route = RPG::MoveRoute.new
      route.repeat = false
      route.wait = true
      route.list = [RPG::MoveCommand.new(code, arguments[code] || []), RPG::MoveCommand.new]
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(205, 0, [1, route]), RPG::EventCommand.new])
      frame = 0
      while interpreter.running? || frame < 4
        raise "route hung: #{code}" if frame >= 100
        interpreter.update
        values = [code, frame, interpreter.running?, character.x, character.y,
          character.real_x, character.real_y, character.direction, character.jump_height,
          character.move_speed, character.move_frequency, character.walk_anime,
          character.step_anime, character.direction_fix, character.through,
          character.transparent, character.character_name, character.character_index,
          character.opacity, character.blend_type, character.move_route_forcing,
          $game_switches[1], $game_variables[1]]
        file.puts(values.map { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }.join("\t"))
        file.flush
        character.update
        frame += 1
      end
    end
    [9, 23, 24].each do |code|
      32.times do
        character = Game_Character.new
        character.moveto(10, 10)
        character.instance_variable_set(:@through, true)
        character.process_move_command(RPG::MoveCommand.new(code))
        if code == 9
          raise 'random move outside adjacent tile' unless (character.x - 10).abs + (character.y - 10).abs == 1
        elsif code == 23
          raise 'random quarter-turn outside left/right' unless [4, 6].include?(character.direction)
        else
          raise 'random direction outside RGSS direction set' unless [2, 4, 6, 8].include?(character.direction)
        end
      end
      file.puts(['random-invariant', code, 32].join("\t"))
    end
    [false, true].each do |skippable|
      event_data = RPG::Event.new(10, 10)
      event_data.id = 1
      character = Game_Event.new(1, event_data)
      $game_map.instance_variable_set(:@events, {1 => character})
      $data_tilesets[1].flags[2] = 0x0f
      map.data[11, 10, 0] = 2
      route = RPG::MoveRoute.new
      route.repeat = false
      route.skippable = skippable
      route.wait = true
      route.list = [RPG::MoveCommand.new(3), RPG::MoveCommand.new(42, [80]), RPG::MoveCommand.new]
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(205, 0, [1, route]), RPG::EventCommand.new])
      8.times do |frame|
        interpreter.update
        file.puts(['blocked', skippable, frame, interpreter.running?, character.x,
          character.y, character.opacity, character.move_route_forcing].join("\t"))
        character.update
      end
      file.flush
      map.data[11, 10, 0] = 1
    end
    event_data = RPG::Event.new(10, 10)
    event_data.id = 1
    character = Game_Event.new(1, event_data)
    $game_map.instance_variable_set(:@events, {1 => character})
    route = RPG::MoveRoute.new
    route.repeat = true
    route.wait = false
    route.list = [RPG::MoveCommand.new(45, ['$game_variables[1] += 1']), RPG::MoveCommand.new]
    interpreter = Game_Interpreter.new
    interpreter.setup([RPG::EventCommand.new(205, 0, [1, route]), RPG::EventCommand.new])
    $game_variables[1] = 0
    8.times do |frame|
      interpreter.update
      file.puts(['repeat', frame, interpreter.running?, character.move_route_forcing, $game_variables[1]].join("\t"))
      character.update
    end
    file.flush
  end
rescue Exception => error
  File.open(File.join(output, 'event_route_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_system, $game_message,
    $game_switches, $game_variables, $data_system, $data_tilesets = saved
end
exit unless $rgss_compat_output
