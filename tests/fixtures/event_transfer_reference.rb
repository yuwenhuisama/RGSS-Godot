output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_message, $game_temp,
  $game_variables, $data_system, $data_tilesets, $data_common_events, $game_switches,
  $rmva_project_base_path]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_tilesets = [nil, RPG::Tileset.new]
  $data_common_events = []
  $game_switches = Game_Switches.new
  $rmva_project_base_path = $event_transfer_base if $event_transfer_base
  target_map = RPG::Map.new(30, 25)
  target_map.tileset_id = 1
  save_data(target_map, 'Data/Map002.rvdata2')
  $game_map = Game_Map.new
  map = RPG::Map.new(40, 30)
  $game_map.instance_variable_set(:@map, map)
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_map.setup_scroll
  $game_party = Game_Party.new
  $game_message = Game_Message.new
  $game_temp = Game_Temp.new
  $game_variables = Game_Variables.new
  $game_variables[1] = 1
  $game_variables[2] = 12
  $game_variables[3] = 14
  $game_player = Game_Player.new
  $game_player.moveto(8, 8)
  cases = [
    ['transfer-direct', [[201, [0, 1, 10, 11, 6, 0]]]],
    ['transfer-variable', [[201, [1, 1, 2, 3, 8, 1]]]],
    ['transparent-on', [[211, [0]]]], ['transparent-off', [[211, [1]]]],
    ['scroll-down', [[204, [2, 2, 6]]]], ['scroll-left', [[204, [4, 2, 6]]]],
    ['scroll-right', [[204, [6, 2, 6]]]], ['scroll-up', [[204, [8, 2, 6]]]],
    ['scroll-sequence', [[204, [6, 1, 5]], [204, [2, 1, 5]]]],
    ['followers-hide', [[216, [1]]]], ['followers-show', [[216, [0]]]],
    ['followers-gather', [[217, []]]],
    ['transfer-cross-map', [[201, [0, 2, 6, 7, 4, 2]]]],
    ['transfer-battle-blocked', [[201, [0, 2, 20, 20, 6, 0]]]],
    ['transfer-message-wait', [[201, [0, 2, 9, 8, 2, 1]]]]
  ]
  File.open(File.join(output, 'event_transfer_reference.tsv'), 'w') do |file|
    cases.each do |name, commands|
      $game_party = Game_Party.new
      $game_party.on_battle_start if name == 'transfer-battle-blocked'
      $game_message.visible = true if name == 'transfer-message-wait'
      list = commands.map { |code, parameters| RPG::EventCommand.new(code, 0, parameters) }
      list << RPG::EventCommand.new
      interpreter = Game_Interpreter.new
      interpreter.setup(list)
      frame = 0
      while interpreter.running? || $game_map.scrolling? || frame < 4
        raise "transfer/scroll hung: #{name}" if frame >= 150
        interpreter.update
        values = [name, frame, interpreter.running?, $game_player.transfer?,
          $game_temp.fade_type, $game_player.x, $game_player.y, $game_player.direction,
          $game_player.transparent, $game_map.display_x, $game_map.display_y,
          $game_map.scrolling?, $game_player.followers.visible,
          $game_player.followers.gathering?, $game_map.map_id, $game_map.width, $game_map.height]
        file.puts(values.map { |value| value.is_a?(Numeric) ? sprintf('%.9f', value) : value.to_s }.join("\t"))
        file.flush
        $game_message.visible = false if name == 'transfer-message-wait' && frame == 2
        $game_player.perform_transfer if $game_player.transfer?
        $game_map.update_scroll
        frame += 1
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_transfer_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_message, $game_temp,
    $game_variables, $data_system, $data_tilesets, $data_common_events, $game_switches,
    $rmva_project_base_path = saved
end
exit unless $rgss_compat_output
