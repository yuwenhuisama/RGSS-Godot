output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_actors, $game_switches,
  $game_variables, $game_self_switches, $data_system, $data_tilesets,
  $data_actors, $data_classes, $data_items, $data_weapons, $data_armors, $data_states]
begin
  $data_system = RPG::System.new
  $data_system.switches = [nil, 'one', 'two']
  $data_system.variables = [nil, 'value']
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[1] = 0
  $data_actors = [nil, RPG::Actor.new]
  $data_actors[1].id = 1
  $data_classes = [nil, RPG::Class.new]
  $data_items = [nil, RPG::Item.new]
  $data_items[1].id = 1
  $data_weapons = []
  $data_armors = []
  $data_states = [nil, RPG::State.new]
  $game_actors = Game_Actors.new
  $game_party = Game_Party.new
  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_self_switches = Game_SelfSwitches.new
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_player = Game_Player.new
  $game_player.moveto(10, 10)
  data = RPG::Event.new(11, 10)
  data.id = 1
  data.pages[0].graphic.character_name = 'Base'
  page = RPG::Event::Page.new
  page.graphic.character_name = 'Qualified'
  condition = page.condition
  condition.switch1_valid = condition.switch2_valid = condition.variable_valid = true
  condition.self_switch_valid = condition.item_valid = condition.actor_valid = true
  condition.switch1_id = 1
  condition.switch2_id = 2
  condition.variable_id = 1
  condition.variable_value = 5
  condition.self_switch_ch = 'A'
  condition.item_id = condition.actor_id = 1
  data.pages << page
  File.open(File.join(output, 'event_page_reference.tsv'), 'w') do |file|
    64.times do |mask|
      $game_switches[1] = mask & 1 != 0
      $game_switches[2] = mask & 2 != 0
      $game_variables[1] = mask & 4 != 0 ? 5 : 4
      $game_self_switches[[1, 1, 'A']] = mask & 8 != 0
      $game_party.lose_item($data_items[1], 99)
      $game_party.gain_item($data_items[1], 1) if mask & 16 != 0
      $game_party.remove_actor(1)
      $game_party.add_actor(1) if mask & 32 != 0
      event = Game_Event.new(1, data)
      file.puts([mask, event.character_name].join("\t"))
      file.flush
    end
    [[0, 1], [0, 0], [1, 1], [2, 1]].each do |trigger, priority|
      data = RPG::Event.new(priority == 0 ? 10 : 11, 10)
      data.id = 2
      data.pages[0].trigger = trigger
      data.pages[0].priority_type = priority
      data.pages[0].list = [RPG::EventCommand.new(230, 0, [1]), RPG::EventCommand.new]
      event = Game_Event.new(1, data)
      $game_map.instance_variable_set(:@events, {2 => event})
      $game_player.set_direction(6)
      if trigger == 0
        $game_player.check_event_trigger_here([0])
        $game_player.check_event_trigger_there([0])
      else
        $game_player.check_event_trigger_touch(11, 10)
      end
      file.puts(['trigger', trigger, priority, event.starting].join("\t"))
      event.clear_starting_flag
      if trigger == 0
        $game_player.check_event_trigger_touch(data.x, data.y)
      else
        $game_player.check_event_trigger_here([0])
        $game_player.check_event_trigger_there([0])
      end
      file.puts(['wrong-trigger', trigger, priority, event.starting].join("\t"))
    end
    [false, true].each do |counter|
      $data_tilesets[1].flags[2] = counter ? 0x80 : 0
      map.data[11, 10, 0] = 2
      data = RPG::Event.new(12, 10)
      data.id = 3
      data.pages[0].priority_type = 1
      data.pages[0].list = [RPG::EventCommand.new(230, 0, [1]), RPG::EventCommand.new]
      event = Game_Event.new(1, data)
      $game_map.instance_variable_set(:@events, {3 => event})
      $game_player.check_event_trigger_there([0])
      file.puts(['counter', counter, event.starting].join("\t"))
    end
    [0, 1].each do |priority|
      data = RPG::Event.new(11, 10)
      data.id = 4
      data.pages[0].trigger = 2
      data.pages[0].priority_type = priority
      data.pages[0].list = [RPG::EventCommand.new(230, 0, [1]), RPG::EventCommand.new]
      event = Game_Event.new(1, data)
      $game_map.instance_variable_set(:@events, {4 => event})
      event.check_event_trigger_touch(10, 10)
      file.puts(['event-touch', priority, event.starting].join("\t"))
      event.clear_starting_flag
      event.check_event_trigger_touch(9, 10)
      file.puts(['event-touch-wrong-position', priority, event.starting].join("\t"))
      event.clear_starting_flag
      event.jump(0, 0)
      event.check_event_trigger_touch(10, 10)
      file.puts(['event-touch-jumping', priority, event.starting].join("\t"))
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_page_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_actors, $game_switches,
    $game_variables, $game_self_switches, $data_system, $data_tilesets,
    $data_actors, $data_classes, $data_items, $data_weapons, $data_armors, $data_states = saved
end
exit unless $rgss_compat_output
