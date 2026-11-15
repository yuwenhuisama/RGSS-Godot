output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_party, $game_variables, $game_system,
  $data_system, $data_items, $data_weapons, $data_armors, $game_timer]
begin
  $data_system = RPG::System.new
  $data_system.variables = [nil] + Array.new(20, 'variable')
  $game_map = Game_Map.new
  $game_message = Game_Message.new
  $game_party = Game_Party.new
  $game_variables = Game_Variables.new
  $game_system = Game_System.new
  $game_timer = Game_Timer.new
  $game_map.instance_variable_set(:@map_id, 7)
  $game_timer.start(300)
  $data_items = [nil, RPG::Item.new]
  $data_weapons = [nil, RPG::Weapon.new]
  $data_armors = [nil, RPG::Armor.new]
  [$data_items[1], $data_weapons[1], $data_armors[1]].each { |item| item.id = 1 }
  $game_variables[1] = 4
  cases = [
    ['gold-add', 125, [0, 0, 50]], ['gold-subtract', 125, [1, 0, 70]],
    ['gold-variable', 125, [0, 1, 1]], ['gold-limit', 125, [0, 0, 999999999]],
    ['item-add', 126, [1, 0, 0, 10]], ['item-subtract', 126, [1, 1, 0, 3]],
    ['item-variable', 126, [1, 0, 1, 1]], ['item-limit', 126, [1, 0, 0, 200]],
    ['weapon-add', 127, [1, 0, 0, 5, false]], ['weapon-subtract', 127, [1, 1, 0, 10, false]],
    ['armor-add', 128, [1, 0, 1, 1, false]], ['armor-subtract', 128, [1, 1, 0, 1, false]],
    ['save-disable', 134, [0]], ['save-enable', 134, [1]],
    ['menu-disable', 135, [0]], ['menu-enable', 135, [1]],
    ['formation-disable', 137, [0]], ['formation-enable', 137, [1]],
    ['window-tone', 138, [Tone.new(-20, 40, 80, 60)]],
    ['battle-bgm', 132, [RPG::BGM.new('Probe', 80, 110)]],
    ['battle-me', 133, [RPG::ME.new('Result', 70, 90)]]
  ]
  3.times { |kind| cases << ["inventory-data-#{kind}", 122, [2, 2, 0, 3, kind, 1, 0]] }
  [0, 1, 2, 3, 5, 6, 7].each { |kind| cases << ["system-data-#{kind}", 122, [2, 2, 0, 3, 7, kind, 0]] }
  3.times do |comparison|
    [99999998, 99999999, 100000000].each do |amount|
      cases << ["gold-condition-#{comparison}-#{amount}", 111, [7, amount, comparison]]
    end
  end
  [8, 9, 10].each { |kind| cases << ["inventory-condition-#{kind}", 111, [kind, 1, false]] }
  File.open(File.join(output, 'event_inventory_reference.tsv'), 'w') do |file|
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
      updates = 0
      while interpreter.running?
        raise "inventory case hung: #{name}" if updates >= 10
        interpreter.update
        updates += 1
      end
      tone = $game_system.window_tone
      bgm = $game_system.battle_bgm
      me = $game_system.battle_end_me
      file.puts([name, updates, $game_party.gold,
        $game_party.item_number($data_items[1]), $game_party.item_number($data_weapons[1]),
        $game_party.item_number($data_armors[1]), $game_system.save_disabled,
        $game_system.menu_disabled, $game_system.formation_disabled,
        tone.red.to_i, tone.green.to_i, tone.blue.to_i, tone.gray.to_i,
        bgm.name, bgm.volume, bgm.pitch, me.name, me.volume, me.pitch, $game_variables[2]].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_inventory_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_message, $game_party, $game_variables, $game_system,
    $data_system, $data_items, $data_weapons, $data_armors, $game_timer = saved
end
exit unless $rgss_compat_output
