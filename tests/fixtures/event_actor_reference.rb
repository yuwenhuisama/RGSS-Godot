output = $rgss_compat_output || '.'
saved = [$game_map, $game_player, $game_party, $game_actors, $game_message,
  $game_variables, $game_temp, $data_system, $data_actors, $data_classes,
  $data_states, $data_skills, $data_items, $data_weapons, $data_armors]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(10, 'variable')
  $data_actors = [nil, RPG::Actor.new, RPG::Actor.new]
  $data_actors[1].id = 1
  $data_actors[2].id = 2
  $data_classes = [nil, RPG::Class.new, RPG::Class.new]
  $data_classes[1].id = 1
  $data_classes[2].id = 2
  $data_states = [nil, RPG::State.new, RPG::State.new]
  $data_states[1].id = 1
  $data_states[2].id = 2
  $data_skills = [nil, RPG::Skill.new]
  $data_skills[1].id = 1
  $data_items = []
  $data_weapons = [nil, RPG::Weapon.new]
  $data_weapons[1].id = 1
  $data_weapons[1].wtype_id = 1
  $data_armors = [nil, RPG::Armor.new]
  $data_armors[1].id = 1
  $data_armors[1].atype_id = 1
  $game_map = Game_Map.new
  $game_actors = Game_Actors.new
  $game_party = Game_Party.new
  $game_message = Game_Message.new
  $game_variables = Game_Variables.new
  $game_temp = Game_Temp.new
  $game_player = Game_Player.new
  $game_variables[1] = 1
  $game_party.gain_item($data_weapons[1], 1)
  $game_party.gain_item($data_armors[1], 1)
  cases = [
    ['party-add', 129, [1, 0, 0]], ['party-add-second', 129, [2, 0, 0]],
    ['hp-subtract', 311, [0, 1, 1, 0, 100, false]],
    ['hp-no-death', 311, [1, 1, 1, 0, 9999, false]],
    ['mp-subtract', 312, [0, 1, 1, 0, 30]],
    ['state-add', 313, [0, 1, 0, 2]], ['state-remove', 313, [0, 1, 1, 2]],
    ['recover', 314, [0, 1]], ['experience', 315, [0, 1, 0, 0, 1000, false]],
    ['level', 316, [0, 1, 0, 0, 2, false]],
    ['parameter', 317, [0, 1, 2, 0, 0, 10]],
    ['skill-learn', 318, [0, 1, 0, 1]], ['skill-forget', 318, [0, 1, 1, 1]],
    ['equip', 319, [1, 0, 1]], ['unequip', 319, [1, 0, 0]],
    ['name', 320, [1, 'Probe Actor']], ['class', 321, [1, 2]],
    ['graphics', 322, [1, 'Actor', 3, 'Face', 2]],
    ['vehicle-graphics', 323, [0, 'Vehicle', 1]], ['nickname', 324, [1, 'Runner']],
    ['party-remove', 129, [2, 1]], ['missing-actor', 320, [99, 'Missing']],
    ['party-reinitialize', 129, [2, 0, 1]],
    ['all-actor-mp', 312, [0, 0, 1, 0, 15]],
    ['variable-actor-hp', 311, [1, 1, 1, 0, 25, false]],
    ['level-lower-bound', 316, [0, 1, 1, 0, 100, false]],
    ['hp-kill-one', 311, [0, 1, 1, 0, 9999, true]],
    ['hp-dead-no-change', 311, [0, 1, 0, 0, 50, false]],
    ['revive', 314, [0, 1]],
    ['equip-again', 319, [1, 0, 1]]
  ]
  [[0, nil], [1, 'Probe Actor'], [2, 2], [3, 1], [4, 1], [6, 2]].each do |kind, operand|
    params = [4, 1, kind]
    params << operand if operand
    cases << ["actor-condition-#{kind}", 111, params]
  end
  12.times do |field|
    cases << ["actor-data-#{field}", 122, [2, 2, 0, 3, 3, 1, field]]
  end
  cases << ['actor-data-missing', 122, [2, 2, 0, 3, 3, 99, 0]]
  cases << ['party-member-data', 122, [2, 2, 0, 3, 6, 0, 0]]
  cases << ['party-member-missing', 122, [2, 2, 0, 3, 6, 99, 0]]
  cases << ['skill-learn-for-condition', 318, [0, 1, 0, 1]]
  cases << ['skill-positive-condition', 111, [4, 1, 3, 1]]
  cases << ['state-add-for-condition', 313, [0, 1, 0, 2]]
  cases << ['state-positive-condition', 111, [4, 1, 6, 2]]
  cases << ['armor-negative-condition', 111, [4, 1, 5, 1]]
  cases << ['armor-equip', 319, [1, 1, 1]]
  cases << ['armor-positive-condition', 111, [4, 1, 5, 1]]
  cases << ['party-remove-condition', 129, [1, 1]]
  cases << ['party-negative-condition', 111, [4, 1, 0]]
  cases << ['party-return-condition', 129, [1, 0, 0]]
  cases << ['wrong-name-condition', 111, [4, 1, 1, 'Different']]
  cases << ['wrong-class-condition', 111, [4, 1, 2, 1]]
  cases << ['weapon-inventory-excludes-equipped', 111, [9, 1, false]]
  cases << ['weapon-inventory-includes-equipped', 111, [9, 1, true]]
  cases << ['armor-inventory-excludes-equipped', 111, [10, 1, false]]
  cases << ['armor-inventory-includes-equipped', 111, [10, 1, true]]
  cases << ['weapon-loss-excludes-equipped', 127, [1, 1, 0, 1, false]]
  cases << ['armor-loss-excludes-equipped', 128, [1, 1, 0, 1, false]]
  cases << ['weapon-loss-includes-equipped', 127, [1, 1, 0, 1, true]]
  cases << ['armor-loss-includes-equipped', 128, [1, 1, 0, 1, true]]
  File.open(File.join(output, 'event_actor_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      list = [RPG::EventCommand.new(code, 0, parameters)]
      if code == 111
        list.concat([RPG::EventCommand.new(122, 1, [2, 2, 0, 0, 1]),
          RPG::EventCommand.new(411, 0, []), RPG::EventCommand.new(122, 1, [2, 2, 0, 0, 0]),
          RPG::EventCommand.new(412, 0, [])])
      end
      list << RPG::EventCommand.new
      interpreter.setup(list)
      count = 0
      while interpreter.running?
        raise "actor command hung: #{name}" if count >= 10
        interpreter.update
        count += 1
      end
      actor = $game_actors[1]
      file.puts([name, count, $game_party.members.map { |member| member.id }.join(','),
        actor.hp, actor.mp, actor.level, actor.exp, actor.atk, actor.state?(2),
        actor.skill_learn?($data_skills[1]), actor.equips[0] ? actor.equips[0].id : 0,
        actor.name, actor.nickname, actor.class.id, actor.character_name,
        actor.character_index, actor.face_name, actor.face_index,
        $game_map.boat.character_name, $game_map.boat.character_index,
        $game_actors[2].hp, $game_actors[2].mp, actor.dead?, $game_variables[2],
        actor.equips[1] ? actor.equips[1].id : 0,
        $game_party.item_number($data_weapons[1]), $game_party.item_number($data_armors[1])].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_actor_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_player, $game_party, $game_actors, $game_message,
    $game_variables, $game_temp, $data_system, $data_actors, $data_classes,
    $data_states, $data_skills, $data_items, $data_weapons, $data_armors = saved
end
exit unless $rgss_compat_output
