output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_temp, $game_message,
  $game_switches, $game_variables, $game_self_switches, $data_system,
  $data_tilesets, $data_common_events]
begin
  $data_system = RPG::System.new
  $data_system.switches = [nil] + Array.new(10, 'switch')
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[1] = 0
  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_self_switches = Game_SelfSwitches.new
  $game_temp = Game_Temp.new
  $game_message = Game_Message.new
  $game_party = Game_Party.new
  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.setup_scroll
  $game_map.setup_parallax
  $game_player = Game_Player.new
  $game_player.moveto(10, 10)
  [0, 3, 4].each_with_index do |trigger, index|
    event = RPG::Event.new(2 + index, 3)
    event.id = index + 1
    page = event.pages[0]
    page.trigger = trigger
    page.list = [RPG::EventCommand.new(122, 0, [index + 1, index + 1, 1, 0, 1]),
      RPG::EventCommand.new(230, 0, [2]), RPG::EventCommand.new]
    if trigger == 3
      page.list.insert(2, RPG::EventCommand.new(123, 0, ['A', 0]))
      disabled = RPG::Event::Page.new
      disabled.condition.self_switch_valid = true
      disabled.condition.self_switch_ch = 'A'
      event.pages << disabled
    end
    map.events[event.id] = event
  end
  $data_common_events = [nil]
  [0, 1, 2].each_with_index do |trigger, index|
    event = RPG::CommonEvent.new
    event.id = index + 1
    event.trigger = trigger
    event.switch_id = 1
    event.list = [RPG::EventCommand.new(122, 0, [index + 4, index + 4, 1, 0, 1]),
      RPG::EventCommand.new(230, 0, [2]), RPG::EventCommand.new]
    event.list.insert(2, RPG::EventCommand.new(121, 0, [1, 1, 1])) if trigger == 1
    $data_common_events << event
  end
  $game_map.setup_events
  $game_map.events[1].start
  $game_temp.reserve_common_event(1)
  $game_switches[1] = true
  File.open(File.join(output, 'event_schedule_reference.tsv'), 'w') do |file|
    24.times do |frame|
      $game_switches[1] = true if frame == 12
      $game_map.update(true)
      file.puts([frame, *(1..6).map { |id| $game_variables[id] },
        $game_switches[1], $game_self_switches[[1, 2, 'A']],
        $game_map.interpreter.event_id, $game_map.interpreter.running?,
        $game_temp.common_event_reserved?, $game_map.events[1].starting,
        $game_map.events[2].starting].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_schedule_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_temp, $game_message,
    $game_switches, $game_variables, $game_self_switches, $data_system,
    $data_tilesets, $data_common_events = saved
end
exit unless $rgss_compat_output
