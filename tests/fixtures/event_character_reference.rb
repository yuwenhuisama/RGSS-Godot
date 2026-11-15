output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_party, $game_variables, $game_switches,
  $game_self_switches, $data_system, $data_tilesets]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_system.switches = [nil] + Array.new(10, 'switch')
  $data_tilesets = [nil, RPG::Tileset.new]
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.instance_variable_set(:@common_events, [])
  $game_message = Game_Message.new
  $game_party = Game_Party.new
  $game_variables = Game_Variables.new
  $game_switches = Game_Switches.new
  $game_self_switches = Game_SelfSwitches.new
  events = {}
  [1, 2].each do |id|
    data = RPG::Event.new(4 + id, 6)
    data.id = id
    data.pages[0].through = true
    events[id] = Game_Event.new(1, data)
  end
  $game_map.instance_variable_set(:@events, events)
  $game_variables[1] = 9
  $game_variables[2] = 10
  route = RPG::MoveRoute.new
  route.repeat = false
  route.wait = true
  route.list = [RPG::MoveCommand.new(29, [5]), RPG::MoveCommand.new(3),
    RPG::MoveCommand.new(14, [1, -1]), RPG::MoveCommand.new(15, [3]),
    RPG::MoveCommand.new(27, [1]), RPG::MoveCommand.new(42, [128]),
    RPG::MoveCommand.new(45, ['$game_variables[3] = 21']), RPG::MoveCommand.new]
  cases = [
    ['event-direct', 203, [1, 0, 8, 9, 6]],
    ['event-variable', 203, [1, 1, 1, 2, 8]],
    ['event-swap', 203, [1, 2, 2, 0, 4]],
    ['event-missing', 203, [99, 0, 1, 1, 2]],
    ['route-wait', 205, [1, route]],
    ['animation-nowait', 212, [1, 2, false]],
    ['balloon-nowait', 213, [1, 3, false]],
    ['erase-self', 214, []]
  ]
  5.times { |field| cases << ["event-data-#{field}", 122, [3, 3, 0, 3, 5, 2, field]] }
  cases << ['event-data-missing', 122, [3, 3, 0, 3, 5, 99, 0]]
  [2, 4, 6, 8].each { |direction| cases << ["event-direction-#{direction}", 111, [6, 2, direction]] }
  property_route = RPG::MoveRoute.new
  property_route.repeat = false
  property_route.wait = false
  property_route.list = [[30, [5]], [32, []], [33, []], [35, []],
    [36, []], [31, []], [34, []], [39, []], [40, []],
    [41, ['RouteProbe', 2]], [43, [1]], [28, [1]], [42, [200]],
    [0, []]].map { |code, params| RPG::MoveCommand.new(code, params) }
  cases << ['route-properties-nowait', 205, [2, property_route]]
  File.open(File.join(output, 'event_character_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      list = [RPG::EventCommand.new(code, 0, parameters)]
      if code == 111
        list.concat([RPG::EventCommand.new(122, 1, [3, 3, 0, 0, 1]),
          RPG::EventCommand.new(411, 0, []), RPG::EventCommand.new(122, 1, [3, 3, 0, 0, 0]),
          RPG::EventCommand.new(412, 0, [])])
      end
      list << RPG::EventCommand.new
      interpreter.setup(list, 1)
      frame = 0
      while interpreter.running? || (name == 'route-properties-nowait' && events[2].move_route_forcing) || frame < 4
        raise "character command hung: #{name}" if frame >= 150
        interpreter.update
        values = [name, frame, interpreter.running?, $game_variables[3], $game_switches[1]]
        events.each_value do |event|
          values.concat([event.x, event.y, event.real_x, event.real_y,
            event.direction, event.opacity, event.move_route_forcing,
            event.jump_height, event.animation_id, event.balloon_id, event.character_name,
            event.move_frequency, event.walk_anime, event.step_anime, event.direction_fix,
            event.transparent, event.blend_type, event.character_index])
        end
        file.puts(values.map { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }.join("\t"))
        file.flush
        events.each_value { |event| event.update }
        frame += 1
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_character_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_party, $game_variables, $game_switches,
    $game_self_switches, $data_system, $data_tilesets = saved
end
exit unless $rgss_compat_output
