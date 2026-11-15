# D03 player/vehicle interaction probe.
# Runs the stock Game_Player, Game_Followers, Game_Follower, Game_Vehicle,
# Game_Map and Game_Event classes on both RGSS300 and RGSS-Godot. Data is
# configured in memory; no movement or interaction method is replaced.
output = $rgss_compat_output || '.'

def pv_fmt(value)
  value.is_a?(Float) ? sprintf('%.9f', value) : value.to_s
end

def pv_bool(value)
  value ? 1 : 0
end

def pv_build_world
  $data_system = RPG::System.new
  $data_system.opt_followers = true
  $data_system.opt_transparent = false
  $data_system.party_members = [1, 2, 3, 4]

  $data_tilesets = [nil, RPG::Tileset.new]
  flags = $data_tilesets[1].flags
  flags[1] = 0x0000   # land: walkable, boat/ship/airship landing allowed
  flags[2] = 0x000f   # water: walk blocked, boat/ship passable, no airship landing
  flags[3] = 0x0200   # walkable, boat blocked
  flags[4] = 0x0400   # walkable, ship blocked
  flags[5] = 0x0800   # walkable, airship landing blocked
  flags[6] = 0x0040   # bush
  flags[7] = 0x0100   # damage floor

  $data_actors = [nil]
  4.times do |index|
    actor = RPG::Actor.new
    actor.id = index + 1
    actor.character_name = "Actor#{index + 1}"
    actor.character_index = index
    $data_actors.push(actor)
  end
  $data_classes = [nil, RPG::Class.new]
  $data_states = [nil, RPG::State.new]
  $data_items = []
  $data_weapons = []
  $data_armors = []
  $data_skills = []
  $data_common_events = []

  $game_switches = Game_Switches.new
  $game_variables = Game_Variables.new
  $game_self_switches = Game_SelfSwitches.new
  $game_temp = Game_Temp.new
  $game_message = Game_Message.new
  $game_system = Game_System.new
  $game_actors = Game_Actors.new
  $game_party = Game_Party.new
  $game_party.setup_starting_members

  $game_map = Game_Map.new
  map = RPG::Map.new(24, 20)
  map.tileset_id = 1
  20.times { |y| 24.times { |x| map.data[x, y, 0] = 1 } }
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@events, {})
  $game_map.instance_variable_set(:@common_events, [])
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.instance_variable_set(:@display_x, 0)
  $game_map.instance_variable_set(:@display_y, 0)
  $game_map.instance_variable_set(:@scroll_direction, 2)
  $game_map.instance_variable_set(:@scroll_rest, 0)
  $game_map.instance_variable_set(:@scroll_speed, 4)
  $game_map.instance_variable_set(:@parallax_loop_x, false)
  $game_map.instance_variable_set(:@parallax_loop_y, false)
  $game_map.instance_variable_set(:@parallax_sx, 0)
  $game_map.instance_variable_set(:@parallax_sy, 0)
  $game_map.instance_variable_set(:@parallax_x, 0)
  $game_map.instance_variable_set(:@parallax_y, 0)
  $game_map.instance_variable_set(:@need_refresh, false)

  $game_player = Game_Player.new
  $game_player.moveto(10, 10)
  $game_player.refresh
  map
end

def pv_scatter_followers(x, y)
  $game_player.followers[0].moveto(x - 2, y)
  $game_player.followers[1].moveto(x - 4, y + 1)
  $game_player.followers[2].moveto(x - 6, y - 1)
end

def pv_add_event(id, x, y, priority_type)
  data = RPG::Event.new(x, y)
  data.id = id
  data.pages[0].priority_type = priority_type
  event = Game_Event.new(1, data)
  $game_map.instance_variable_get(:@events)[id] = event
  event
end

def pv_make_record(file)
  proc do |label, frame|
    player = $game_player
    vehicle = player.vehicle
    followers = player.followers
    values = [label, frame,
      player.x, player.y, pv_fmt(player.real_x), pv_fmt(player.real_y),
      player.direction, player.move_speed, pv_bool(player.transparent), pv_bool(player.through),
      pv_bool(player.moving?), pv_bool(player.stopping?), pv_bool(player.jumping?),
      pv_bool(player.in_boat?), pv_bool(player.in_ship?), pv_bool(player.in_airship?),
      pv_bool(player.instance_variable_get(:@vehicle_getting_on)),
      pv_bool(player.instance_variable_get(:@vehicle_getting_off)),
      pv_fmt(player.screen_x), pv_fmt(player.screen_y), player.bush_depth,
      $game_map.display_x, $game_map.display_y]
    if vehicle
      values.push(vehicle.instance_variable_get(:@type).to_s,
        vehicle.x, vehicle.y, pv_fmt(vehicle.real_x), pv_fmt(vehicle.real_y),
        vehicle.direction, vehicle.altitude, pv_bool(vehicle.driving), vehicle.speed,
        pv_bool(vehicle.movable?), pv_fmt(vehicle.screen_y), vehicle.screen_z,
        pv_bool(vehicle.transparent), vehicle.priority_type,
        pv_bool(vehicle.walk_anime), pv_bool(vehicle.step_anime))
    else
      16.times { values.push('-') }
    end
    values.push(pv_bool(followers.gathering?), pv_bool(followers.gather?),
      pv_bool(followers.moving?), pv_bool(followers.visible))
    3.times do |index|
      follower = followers[index]
      values.push(follower.x, follower.y, pv_fmt(follower.real_x), pv_fmt(follower.real_y),
        follower.direction, pv_bool(follower.moving?), pv_bool(follower.gather?),
        pv_bool(follower.transparent), follower.opacity, follower.move_speed,
        pv_fmt(follower.screen_x), pv_fmt(follower.screen_y))
    end
    file.puts(values.join("\t"))
    file.flush
  end
end

# Records the state, then advances one real Scene_Map frame
# ($game_map.update(true) followed by $game_player.update). The block, when
# given, is evaluated against the state just recorded.
def pv_run_phase(label, max_frames, record)
  frame = 0
  while frame < max_frames
    record.call(label, frame)
    break if block_given? && yield
    $game_map.update(true)
    $game_player.update
    frame += 1
  end
  frame
end

def pv_board(record, prefix)
  boarded = $game_player.get_on_vehicle
  record.call("#{prefix}-get-on-return-#{pv_bool(boarded)}", 0)
  pv_run_phase("#{prefix}-board", 200, record) do
    $game_player.transparent && !$game_player.instance_variable_get(:@vehicle_getting_on)
  end
  pv_run_phase("#{prefix}-drive", 6, record)
end

def pv_case_boat(record)
  map = pv_build_world
  map.data[12, 10, 0] = 2
  map.data[13, 10, 0] = 2
  $game_map.boat.set_location(1, 12, 10)
  $game_player.moveto(11, 10)
  $game_player.set_direction(6)
  $game_player.instance_variable_set(:@move_speed, 6)
  pv_scatter_followers(11, 10)
  pv_run_phase('boat-idle', 1, record)
  pv_board(record, 'boat')
  $game_player.set_direction(6)
  rejected = $game_player.get_off_vehicle
  record.call("boat-reject-water-return-#{pv_bool(rejected)}", 0)
  pv_run_phase('boat-reject-water', 6, record)
  $game_player.move_straight(6)
  pv_run_phase('boat-drive-water', 20, record) { !$game_player.moving? }
  $game_player.set_direction(6)
  accepted = $game_player.get_off_vehicle
  record.call("boat-dismount-return-#{pv_bool(accepted)}", 0)
  pv_run_phase('boat-dismount', 80, record) do
    !$game_player.instance_variable_get(:@vehicle_getting_off) && !$game_player.in_boat?
  end
  pv_run_phase('boat-walk', 8, record)
end

def pv_case_boat_event(record)
  map = pv_build_world
  map.data[12, 10, 0] = 2
  map.data[13, 10, 0] = 2
  event = pv_add_event(1, 14, 10, 1)
  $game_map.boat.set_location(1, 12, 10)
  $game_player.moveto(11, 10)
  $game_player.set_direction(6)
  $game_player.instance_variable_set(:@move_speed, 6)
  pv_scatter_followers(11, 10)
  pv_board(record, 'boat-event')
  $game_player.set_direction(6)
  rejected_water = $game_player.get_off_vehicle
  record.call("boat-event-reject-water-return-#{pv_bool(rejected_water)}", 0)
  $game_player.move_straight(6)
  pv_run_phase('boat-event-drive-water', 20, record) { !$game_player.moving? }
  $game_player.set_direction(6)
  rejected_event = $game_player.get_off_vehicle
  record.call("boat-event-reject-event-return-#{pv_bool(rejected_event)}", 0)
  pv_run_phase('boat-event-reject-event', 6, record)
  event.erase
  accepted = $game_player.get_off_vehicle
  record.call("boat-event-dismount-return-#{pv_bool(accepted)}", 0)
  pv_run_phase('boat-event-dismount', 80, record) do
    !$game_player.instance_variable_get(:@vehicle_getting_off) && !$game_player.in_boat?
  end
  pv_run_phase('boat-event-walk', 8, record)
end

def pv_case_ship(record)
  map = pv_build_world
  map.data[14, 10, 0] = 2
  map.data[15, 10, 0] = 2
  $game_map.ship.set_location(1, 14, 10)
  $game_player.moveto(13, 10)
  $game_player.set_direction(6)
  $game_player.instance_variable_set(:@move_speed, 6)
  pv_scatter_followers(13, 10)
  pv_run_phase('ship-idle', 1, record)
  pv_board(record, 'ship')
  $game_player.set_direction(6)
  rejected = $game_player.get_off_vehicle
  record.call("ship-reject-water-return-#{pv_bool(rejected)}", 0)
  pv_run_phase('ship-reject-water', 6, record)
  $game_player.move_straight(6)
  pv_run_phase('ship-drive-water', 20, record) { !$game_player.moving? }
  $game_player.set_direction(6)
  accepted = $game_player.get_off_vehicle
  record.call("ship-dismount-return-#{pv_bool(accepted)}", 0)
  pv_run_phase('ship-dismount', 80, record) do
    !$game_player.instance_variable_get(:@vehicle_getting_off) && !$game_player.in_ship?
  end
  pv_run_phase('ship-walk', 8, record)
end

def pv_case_airship(record)
  map = pv_build_world
  map.data[17, 10, 0] = 2
  pv_add_event(1, 18, 10, 0)
  $game_map.airship.set_location(1, 16, 10)
  $game_player.moveto(16, 10)
  $game_player.set_direction(6)
  $game_player.instance_variable_set(:@move_speed, 6)
  pv_scatter_followers(16, 10)
  pv_run_phase('airship-idle', 1, record)
  boarded = $game_player.get_on_vehicle
  record.call("airship-get-on-return-#{pv_bool(boarded)}", 0)
  pv_run_phase('airship-board', 220, record) do
    $game_player.transparent &&
      !$game_player.instance_variable_get(:@vehicle_getting_on) &&
      $game_map.airship.altitude == 32
  end
  pv_run_phase('airship-cruise', 6, record)
  $game_player.move_straight(6)
  pv_run_phase('airship-move-water', 20, record) { !$game_player.moving? }
  rejected_terrain = $game_player.get_off_vehicle
  record.call("airship-reject-water-return-#{pv_bool(rejected_terrain)}", 0)
  pv_run_phase('airship-reject-water', 6, record)
  $game_player.move_straight(6)
  pv_run_phase('airship-move-event', 20, record) { !$game_player.moving? }
  rejected_event = $game_player.get_off_vehicle
  record.call("airship-reject-event-return-#{pv_bool(rejected_event)}", 0)
  pv_run_phase('airship-reject-event', 6, record)
  $game_player.move_straight(6)
  pv_run_phase('airship-move-clear', 20, record) { !$game_player.moving? }
  accepted = $game_player.get_off_vehicle
  record.call("airship-dismount-return-#{pv_bool(accepted)}", 0)
  pv_run_phase('airship-descent', 120, record) do
    !$game_player.instance_variable_get(:@vehicle_getting_off) && !$game_player.in_airship?
  end
  pv_run_phase('airship-landed', 8, record)
end

def pv_case_followers(record)
  pv_build_world
  $game_player.moveto(10, 10)
  $game_player.instance_variable_set(:@move_speed, 6)
  pv_scatter_followers(10, 10)
  $game_player.followers.gather
  pv_run_phase('follower-gather', 200, record) { !$game_player.followers.gathering? }
  pv_run_phase('follower-settled', 2, record)
  $game_player.move_straight(6)
  pv_run_phase('follower-lead-move', 20, record) { !$game_player.moving? }
  pv_run_phase('follower-chase', 30, record)
  $game_player.moveto(12, 12)
  pv_run_phase('follower-sync', 6, record)
end

saved = [$game_map, $game_player, $game_party, $game_actors, $game_system, $game_message,
  $game_temp, $game_switches, $game_variables, $game_self_switches, $data_system,
  $data_tilesets, $data_actors, $data_classes, $data_states, $data_items, $data_weapons,
  $data_armors, $data_skills, $data_common_events]
begin
  File.open(File.join(output, 'player_vehicle_reference.tsv'), 'w') do |file|
    record = pv_make_record(file)
    pv_case_boat(record)
    pv_case_boat_event(record)
    pv_case_ship(record)
    pv_case_airship(record)
    pv_case_followers(record)
  end
rescue Exception => error
  File.open(File.join(output, 'player_vehicle_error.txt'), 'w') do |file|
    file.puts(error.class.to_s, error.message, error.backtrace)
  end
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_actors, $game_system, $game_message,
    $game_temp, $game_switches, $game_variables, $game_self_switches, $data_system,
    $data_tilesets, $data_actors, $data_classes, $data_states, $data_items, $data_weapons,
    $data_armors, $data_skills, $data_common_events = saved
end
exit unless $rgss_compat_output
