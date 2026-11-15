output = $rgss_compat_output || '.'
DataManager.load_database
DataManager.create_game_objects
$game_party.setup_starting_members
# This fixture measures manager outcomes. Actual message/input rendering is
# covered by test_battle_flow.gd, not by this synchronous wait callback.
BattleManager.method_wait_for_message = proc { $game_message.clear }
$game_system.battle_bgm = RPG::BGM.new
$game_system.battle_end_me = RPG::ME.new
File.open(File.join(output, 'battle_end_reference.tsv'), 'w') do |file|
  ['escape-success', 'escape-failure', 'abort', 'allowed-defeat', 'gameover', 'victory'].each do |ending|
    DataManager.create_game_objects
    $game_party.setup_starting_members
    $game_system.battle_bgm = RPG::BGM.new
    $game_system.battle_end_me = RPG::ME.new
    BattleManager.setup(1, true, ending != 'gameover')
    BattleManager.save_bgm_and_bgs
    SceneManager.instance_variable_set(:@scene, Scene_Map.new)
    SceneManager.call(Scene_Battle)
    results = []
    BattleManager.event_proc = proc { |result| results << result }
    $game_party.on_battle_start
    $game_troop.on_battle_start
    before_gold = $game_party.gold
    before_exp = $game_party.members.map { |actor| actor.exp }
    case ending
    when 'escape-success'
      BattleManager.instance_variable_set(:@preemptive, true)
      BattleManager.process_escape
    when 'escape-failure'
      BattleManager.instance_variable_set(:@preemptive, false)
      BattleManager.instance_variable_set(:@escape_ratio, -1.0)
      BattleManager.process_escape
    when 'abort'
      BattleManager.process_abort
    when 'allowed-defeat', 'gameover'
      $game_party.battle_members.each { |actor| actor.hp = 0 }
      BattleManager.process_defeat
    when 'victory'
      $game_troop.members.each { |enemy| enemy.hp = 0 }
      BattleManager.process_victory
    end
    file.puts [ending, results.join(','), SceneManager.scene.class.to_s,
      $game_party.in_battle, $game_party.gold-before_gold,
      $game_party.members.each_with_index.map { |actor,index| actor.exp-before_exp[index] }.join(','),
      $game_party.battle_members.map { |actor| actor.hp }.join(',')].join("\t")
    file.flush
  end
end
File.open(File.join(output, 'battle_initiative_reference.tsv'), 'w') do |file|
  [[false,false],[true,false],[false,true]].each do |preemptive,surprise|
    DataManager.create_game_objects
    $game_party.setup_starting_members
    BattleManager.setup(1,true,true)
    BattleManager.instance_variable_set(:@preemptive,preemptive)
    BattleManager.instance_variable_set(:@surprise,surprise)
    $game_party.on_battle_start
    $game_troop.on_battle_start
    accepts_input = BattleManager.input_start
    BattleManager.make_action_orders
    order = BattleManager.instance_variable_get(:@action_battlers)
    file.puts [preemptive,surprise,accepts_input,
      order.count { |battler| battler.is_a?(Game_Actor) },
      order.count { |battler| battler.is_a?(Game_Enemy) }].join("\t")
    file.flush
  end
end
exit unless $battle_end_host
