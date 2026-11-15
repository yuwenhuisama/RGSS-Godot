output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_troop, $game_message,
  $game_variables, $data_system, $data_enemies, $data_troops, SceneManager.scene,
  SceneManager.instance_variable_get(:@stack)]
battle_saved = BattleManager.instance_variables.map { |name| [name, BattleManager.instance_variable_get(name)] }
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_enemies = [nil, RPG::Enemy.new]
  $data_enemies[1].id = 1
  troop = RPG::Troop.new
  troop.id = 1
  troop.members = [RPG::Troop::Member.new]
  $data_troops = [nil, troop]
  $game_map = Game_Map.new
  $game_map.instance_variable_set(:@map, RPG::Map.new(24, 20))
  $game_party = Game_Party.new
  $game_troop = Game_Troop.new
  $game_message = Game_Message.new
  $game_variables = Game_Variables.new
  $game_variables[1] = 1
  $game_player = Game_Player.new
  File.open(File.join(output, 'event_battle_reference.tsv'), 'w') do |file|
    encounter = RPG::Map::Encounter.new
    encounter.troop_id = 1
    encounter.weight = 1
    $game_map.instance_variable_get(:@map).encounter_list = [encounter]
    [[0, 0], [0, 1], [0, 2], [1, 0], [2, 0]].each do |operand, result|
      SceneManager.instance_variable_set(:@scene, Scene_Map.new)
      SceneManager.instance_variable_set(:@stack, [])
      list = [RPG::EventCommand.new(301, 0, [operand, 1, true, true])]
      [601, 602, 603].each_with_index do |code, index|
        list << RPG::EventCommand.new(code, 0, [])
        list << RPG::EventCommand.new(122, 1, [2, 2, 0, 0, 10 + index])
      end
      list << RPG::EventCommand.new(604, 0, [])
      list << RPG::EventCommand.new
      interpreter = Game_Interpreter.new
      interpreter.setup(list)
      3.times do |frame|
        interpreter.update
        file.puts([operand, result, frame, interpreter.running?, SceneManager.scene.class.to_s,
          $game_troop.members.size, BattleManager.can_escape?, $game_variables[2]].join("\t"))
        file.flush
        BattleManager.battle_end(result) if frame == 0
      end
      raise 'battle branch interpreter unfinished' if interpreter.running?
    end
    $game_party.on_battle_start
    SceneManager.instance_variable_set(:@scene, Scene_Map.new)
    interpreter = Game_Interpreter.new
    interpreter.setup([RPG::EventCommand.new(301, 0, [0, 1, true, true]), RPG::EventCommand.new])
    3.times do |frame|
      interpreter.update
      file.puts(['battle-start-blocked', frame, interpreter.running?, SceneManager.scene.class.to_s].join("\t"))
      file.flush
    end
    interpreter = Game_Interpreter.new
    interpreter.setup([RPG::EventCommand.new(340, 0, []), RPG::EventCommand.new])
    3.times do |frame|
      interpreter.update
      file.puts(['abort', frame, interpreter.running?, BattleManager.aborting?].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_battle_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  File.open(File.join(output, 'event_battle_teardown.txt'), 'w') { |file| file.puts('restore globals') }
  $game_map, $game_player, $game_party, $game_troop, $game_message,
    $game_variables, $data_system, $data_enemies, $data_troops = saved[0, 9]
  SceneManager.instance_variable_set(:@scene, saved[9])
  SceneManager.instance_variable_set(:@stack, saved[10])
  File.open(File.join(output, 'event_battle_teardown.txt'), 'a') { |file| file.puts('restore manager') }
  BattleManager.init_members
  battle_saved.each { |name, value| BattleManager.instance_variable_set(name, value) }
  File.open(File.join(output, 'event_battle_teardown.txt'), 'a') { |file| file.puts('restore complete') }
end
exit unless $rgss_compat_output
