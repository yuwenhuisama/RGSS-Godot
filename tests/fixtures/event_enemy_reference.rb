output = $rgss_compat_output || '.'
saved = [$game_map, $game_party, $game_troop, $game_message, $game_variables,
  $data_system, $data_enemies, $data_troops, $data_states, $data_skills]
battle_saved = BattleManager.instance_variables.map { |name| [name, BattleManager.instance_variable_get(name)] }
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_enemies = [nil, RPG::Enemy.new, RPG::Enemy.new]
  $data_enemies[1].id = 1
  $data_enemies[1].name = 'First'
  $data_enemies[1].params = [200, 80, 20, 20, 20, 20, 20, 20]
  $data_enemies[2].id = 2
  $data_enemies[2].name = 'Second'
  $data_enemies[2].params = [300, 120, 30, 30, 30, 30, 30, 30]
  troop = RPG::Troop.new
  troop.id = 1
  troop.members = [RPG::Troop::Member.new, RPG::Troop::Member.new]
  troop.members[1].hidden = true
  $data_troops = [nil, troop]
  $data_states = [nil, RPG::State.new, RPG::State.new]
  $data_states[1].id = 1
  $data_states[2].id = 2
  $data_skills = [nil, RPG::Skill.new]
  $data_skills[1].id = 1
  $game_map = Game_Map.new
  $game_party = Game_Party.new
  $game_party.on_battle_start
  $game_troop = Game_Troop.new
  $game_troop.setup(1)
  $game_message = Game_Message.new
  $game_variables = Game_Variables.new
  cases = [
    ['hp-subtract', 331, [0, 1, 0, 30, false]],
    ['hp-no-death', 331, [0, 1, 0, 9999, false]],
    ['mp-subtract-all', 332, [-1, 1, 0, 20]],
    ['state-add', 333, [0, 0, 2]], ['state-remove', 333, [0, 1, 2]],
    ['recover-all', 334, [-1]], ['appear', 335, [1]],
    ['transform', 336, [0, 2]], ['animation', 337, [-1, 3]],
    ['missing-enemy', 332, [99, 1, 0, 10]],
    ['enemy-kill', 331, [0, 1, 0, 9999, true]],
    ['enemy-dead-no-change', 331, [0, 0, 0, 50, false]],
    ['enemy-revive', 334, [0]]
  ]
  10.times { |field| cases << ["enemy-data-#{field}", 122, [1, 1, 0, 3, 4, 0, field]] }
  cases << ['enemy-data-missing', 122, [1, 1, 0, 3, 4, 99, 0]]
  cases << ['enemy-condition-alive', 111, [5, 0, 0]]
  cases << ['enemy-condition-state-absent', 111, [5, 0, 1, 2]]
  cases << ['enemy-state-again', 333, [0, 0, 2]]
  cases << ['enemy-condition-state-present', 111, [5, 0, 1, 2]]
  cases << ['enemy-condition-missing', 111, [5, 99, 0]]
  File.open(File.join(output, 'event_enemy_reference.tsv'), 'w') do |file|
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
      count = 0
      while interpreter.running?
        raise "enemy command hung: #{name}" if count >= 10
        interpreter.update
        count += 1
      end
      values = [name, count]
      $game_troop.members.each do |enemy|
        values.concat([enemy.enemy_id, enemy.name, enemy.hp, enemy.mp, enemy.mhp,
          enemy.mmp, enemy.hidden?, enemy.state?(2), enemy.animation_id])
      end
      values << $game_variables[1]
      file.puts(values.join("\t"))
      file.flush
    end
    [0, -2].each do |target|
      BattleManager.init_members
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(339, 0, [0, 0, 1, target]), RPG::EventCommand.new])
      4.times do |frame|
        interpreter.update
        battler = BattleManager.action_forced_battler
        action = $game_troop.members[0].current_action
        file.puts(['force', target, frame, interpreter.running?, BattleManager.action_forced?,
          battler ? battler.enemy_id : 0, action ? action.item.id : 0,
          action ? action.target_index : -99].join("\t"))
        file.flush
        # Acknowledge the public action queue; actual battle execution is E04.
        BattleManager.clear_action_force if frame == 1
      end
      raise 'forced action event unfinished' if interpreter.running?
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_enemy_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_party, $game_troop, $game_message, $game_variables,
    $data_system, $data_enemies, $data_troops, $data_states, $data_skills = saved
  BattleManager.init_members
  battle_saved.each { |name, value| BattleManager.instance_variable_set(name, value) }
end
exit unless $rgss_compat_output
