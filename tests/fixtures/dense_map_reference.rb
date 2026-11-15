# Shared D09 dense-map scheduling trace.
#
# Runs unchanged on original RGSS300 and on the Godot port through
# tests/test_dense_map_runtime.gd -- --fixture. It drives the stock update path
# directly ($game_map.update(true) plus $game_player.update) so the frame index
# is exact and independent of the host renderer or frame pacing.
#
# Fixture: 24 simultaneous map events on a 20x15 map.
#   16 parallel (trigger 4): own counter + 30-frame wait, activated at frame 0.
#   4 autorun (trigger 3): own latch switch, one increment then latch off.
#   4 event-touch (trigger 2): forced one step into the player at frames
#     40/60/80/100, because stock gates event-touch starts on
#     `$game_map.interpreter.running?`.
# Event 1 also carries a forced non-skippable move route, so route progress and
# real_x/real_y are traced while its parallel interpreter keeps running.
#
# Every frame writes one player row and one row per event. A missing event is
# visible as an absent id, never as a smaller total.

output = $rgss_compat_output || '.'
file = File.open(File.join(output, 'dense_map_reference.tsv'), 'w')
saved = [$game_map, $game_player, $game_party, $game_temp, $game_message,
  $game_switches, $game_variables, $game_self_switches, $data_system,
  $data_tilesets, $data_common_events, $game_system]
begin
  $data_system = RPG::System.new
  $data_system.switches = [nil] + Array.new(40, 'switch')
  $data_system.variables = [nil] + Array.new(40, 'variable')
  $data_system.opt_followers = false
  $data_system.start_map_id = 1
  $data_system.start_x = 15
  $data_system.start_y = 11
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_tilesets[1].flags[1] = 0
  $data_tilesets[1].flags[2] = 0
  $data_common_events = [nil]
  $game_system = Game_System.new
  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_self_switches = Game_SelfSwitches.new
  $game_temp = Game_Temp.new
  $game_message = Game_Message.new
  $game_party = Game_Party.new
  $game_map = Game_Map.new
  map = RPG::Map.new(20, 15)
  map.tileset_id = 1
  15.times { |y| 20.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.setup_scroll
  $game_map.setup_parallax
  $game_map.setup_battleback
  $game_player = Game_Player.new
  $game_player.moveto(15, 11)
  $game_player.set_direction(2)

  counter = lambda do |variable_id|
    [RPG::EventCommand.new(122, 0, [variable_id, variable_id, 1, 0, 1]),
      RPG::EventCommand.new(230, 0, [30]), RPG::EventCommand.new]
  end
  single = lambda do |variable_id|
    [RPG::EventCommand.new(122, 0, [variable_id, variable_id, 1, 0, 1]), RPG::EventCommand.new]
  end
  build = lambda do |id, x, y, trigger, priority, switch_id, variable_id, list|
    event = RPG::Event.new(x, y)
    event.id = id
    idle = event.pages[0]
    idle.trigger = 0
    idle.priority_type = 0
    idle.list = [RPG::EventCommand.new]
    page = RPG::Event::Page.new
    page.condition.switch1_valid = true
    page.condition.switch1_id = switch_id
    page.trigger = trigger
    page.priority_type = priority
    page.list = list
    event.pages << page
    map.events[id] = event
    [id, variable_id]
  end

  rows = []
  index = 0
  16.times do |i|
    # Event 1 sits in a clear lane so its forced route actually advances.
    x = i == 0 ? 2 : 4 + ((i - 1) % 8)
    y = i == 0 ? 12 : 2 + ((i - 1) / 8)
    rows << build.call(1 + index, x, y, 4, 0, 1, 1 + index, counter.call(1 + index))
    index += 1
  end
  4.times do |i|
    list = [RPG::EventCommand.new(122, 0, [1 + index, 1 + index, 1, 0, 1]),
      RPG::EventCommand.new(121, 0, [2 + i, 2 + i, 1]), RPG::EventCommand.new]
    rows << build.call(1 + index, 2 + i, 6, 3, 0, 2 + i, 1 + index, list)
    index += 1
  end
  [[14, 11], [16, 11], [15, 10], [15, 12]].each do |x, y|
    rows << build.call(1 + index, x, y, 2, 1, 1, 1 + index, single.call(1 + index))
    index += 1
  end
  raise 'dense fixture event count' unless rows.size == 24

  $game_map.setup_events
  $game_switches[1] = true
  (2..5).each { |id| $game_switches[id] = true }

  header = ['frame', 'player', $game_player.x, $game_player.y,
    sprintf('%.9f', $game_player.real_x), sprintf('%.9f', $game_player.real_y),
    $game_map.interpreter.running?, $game_map.interpreter.event_id,
    $game_temp.common_event_reserved?]
  file.puts(header.join("\t"))
  file.flush

  touch_schedule = { 40 => [21, 3], 60 => [22, 2], 80 => [23, 1], 100 => [24, 4] }
  120.times do |frame|
    if frame == 1
      # Forced after the frame-0 page refresh, which resets the event's route.
      route = RPG::MoveRoute.new
      route.repeat = false
      route.skippable = false
      route.wait = false
      route.list = [RPG::MoveCommand.new(3), RPG::MoveCommand.new]
      $game_map.events[1].force_move_route(route)
    end
    if touch_schedule.key?(frame)
      id, code = touch_schedule[frame]
      forced = RPG::MoveRoute.new
      forced.repeat = false
      forced.skippable = true
      forced.wait = false
      forced.list = [RPG::MoveCommand.new(code), RPG::MoveCommand.new]
      $game_map.events[id].force_move_route(forced)
    end
    $game_map.update(true)
    $game_player.update
    file.puts([frame, 'player', $game_player.x, $game_player.y,
      sprintf('%.9f', $game_player.real_x), sprintf('%.9f', $game_player.real_y),
      $game_map.interpreter.running?, $game_map.interpreter.event_id,
      $game_temp.common_event_reserved?].join("\t"))
    rows.each do |id, variable_id|
      event = $game_map.events[id]
      file.puts([frame, id, $game_variables[variable_id],
        event.x, event.y, sprintf('%.9f', event.real_x), sprintf('%.9f', event.real_y),
        event.starting, event.move_route_forcing, event.pattern,
        event.direction, event.instance_variable_get(:@stop_count)].join("\t"))
    end
    file.flush
  end
rescue Exception => error
  File.open(File.join(output, 'dense_map_reference_error.txt'), 'w') do |log|
    log.puts(error.class.to_s, error.message, error.backtrace)
  end
  raise if $rgss_compat_output
ensure
  file.close if file && !file.closed?
  $game_map, $game_player, $game_party, $game_temp, $game_message,
    $game_switches, $game_variables, $game_self_switches, $data_system,
    $data_tilesets, $data_common_events, $game_system = saved
end
exit unless $rgss_compat_output
