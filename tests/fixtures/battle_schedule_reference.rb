output=$rgss_compat_output || '.'
unless $battle_schedule_host
  DataManager.load_database
  DataManager.create_game_objects
  $game_party.setup_starting_members
end
$game_party.on_battle_start
BattleManager.setup(1,true,true)
File.open(File.join(output,'battle_schedule_reference.tsv'),'w') do |file|
  [0,1,2].each do |span|
    troop=RPG::Troop.new
    troop.id=$data_troops.size
    troop.members=[RPG::Troop::Member.new]
    troop.members[0].enemy_id=1
    page=RPG::Troop::Page.new
    troop.pages=[page]
    page.span=span
    page.condition.switch_valid=true
    switch_id=$data_system.switches.size
    variable_id=$data_system.variables.size
    $data_system.switches << 'Battle page condition'
    $data_system.variables << 'Battle page count'
    $game_switches[switch_id]=true
    page.condition.switch_id=switch_id
    page.list=[RPG::EventCommand.new(122,0,[variable_id,variable_id,1,0,1]),RPG::EventCommand.new]
    $data_troops << troop
    $game_troop.setup(troop.id)
    6.times do |frame|
      $game_troop.increase_turn if frame==3
      $game_troop.setup_battle_event
      $game_troop.interpreter.update
      file.puts ['span',span,frame,$game_troop.turn_count,$game_variables[variable_id],$game_troop.interpreter.running?].join("\t")
      file.flush
    end
    $game_switches[switch_id]=false
    $game_variables[variable_id]=0
    $data_system.switches.pop
    $data_system.variables.pop
    $data_troops.pop
  end
  BattleManager.setup(1,true,true)
  actor=$game_party.members[0]
  $game_party.make_actions
  $game_troop.make_actions
  BattleManager.make_action_orders
  before=BattleManager.instance_variable_get(:@action_battlers).include?(actor)
  actor.last_target_index=1
  actor.force_action(1,-2)
  BattleManager.force_action(actor)
  file.puts ['force',before,BattleManager.action_forced?,BattleManager.action_forced_battler.equal?(actor),
    actor.current_action.forcing,actor.current_action.target_index,
    BattleManager.instance_variable_get(:@action_battlers).include?(actor)].join("\t")
  BattleManager.clear_action_force
  file.puts ['force-clear',BattleManager.action_forced?].join("\t")
end
File.open(File.join(output,'battle_page_conditions.tsv'),'w') do |file|
  BattleManager.setup(1,true,true)
  page=RPG::Troop::Page.new
  file.puts ['none',$game_troop.conditions_met?(page)].join("\t")
  page.condition.turn_valid=true
  [[0,0,0],[1,1,0],[2,1,0],[1,1,2],[2,1,2],[3,1,2]].each do |turn,a,b|
    $game_troop.instance_variable_set(:@turn_count,turn)
    page.condition.turn_a=a
    page.condition.turn_b=b
    file.puts ['turn',turn,a,b,$game_troop.conditions_met?(page)].join("\t")
  end
  page.condition.turn_valid=false
  page.condition.enemy_valid=true
  page.condition.enemy_index=0
  enemy=$game_troop.members[0]
  enemy.hp=enemy.mhp/2
  [49,50,51].each do |threshold|
    page.condition.enemy_hp=threshold
    file.puts ['enemy-hp',threshold,$game_troop.conditions_met?(page)].join("\t")
  end
  page.condition.enemy_index=99
  file.puts ['enemy-missing',$game_troop.conditions_met?(page)].join("\t")
  page.condition.enemy_valid=false
  page.condition.actor_valid=true
  page.condition.actor_id=1
  actor=$game_actors[1]
  actor.hp=actor.mhp/2
  [49,50,51].each do |threshold|
    page.condition.actor_hp=threshold
    file.puts ['actor-hp',threshold,$game_troop.conditions_met?(page)].join("\t")
  end
  page.condition.actor_valid=false
  page.condition.switch_valid=true
  switch_id=$data_system.switches.size
  $data_system.switches << 'Battle condition probe'
  page.condition.switch_id=switch_id
  [false,true].each do |value|
    $game_switches[switch_id]=value
    file.puts ['switch',value,$game_troop.conditions_met?(page)].join("\t")
  end
  page.condition.turn_ending=true
  [false,true].each do |ending|
    BattleManager.instance_variable_set(:@phase,ending ? :turn_end : :input)
    file.puts ['turn-ending',ending,$game_troop.conditions_met?(page)].join("\t")
  end
  $game_switches[switch_id]=false
  $data_system.switches.pop
end
$game_party.on_battle_end
File.open(File.join(output,'battle_order_reference.tsv'),'w') do |file|
  $game_party.add_actor(2)
  $game_party.members.each { |member| member.recover_all }
  $game_party.on_battle_start
  BattleManager.setup(1,true,true)
  BattleManager.instance_variable_set(:@preemptive,true)
  slow=RPG::Skill.new
  slow.id=$data_skills.size
  slow.speed=0
  fast=RPG::Skill.new
  fast.id=slow.id+1
  fast.speed=1000
  $data_skills << slow << fast
  $game_party.make_actions
  $game_party.members[0].current_action.set_skill(slow.id)
  $game_party.members[1].current_action.set_skill(fast.id)
  BattleManager.make_action_orders
  subjects=[]
  while subject=BattleManager.next_subject
    subjects << subject.id
  end
  file.puts ['speed-order',subjects.join(',')].join("\t")
  actor=$game_party.members[0]
  actor.hp=0
  interpreter=Game_Interpreter.new
  interpreter.setup([RPG::EventCommand.new(339,0,[1,actor.id,1,0]),RPG::EventCommand.new])
  2.times { interpreter.update }
  file.puts ['dead-force',BattleManager.action_forced?,interpreter.running?,actor.current_action.nil?].join("\t")
  enemy=$game_troop.members[0]
  enemy.last_target_index=0
  enemy.force_action(1,-2)
  BattleManager.force_action(enemy)
  file.puts ['enemy-force',BattleManager.action_forced_battler.equal?(enemy),enemy.current_action.forcing,enemy.current_action.target_index].join("\t")
  BattleManager.clear_action_force
  $data_skills.pop
  $data_skills.pop
  actor.recover_all
  $game_party.on_battle_end
end
exit unless $battle_schedule_host
