output=$rgss_compat_output || '.'
unless $battle_effect_host
  DataManager.load_database
  DataManager.create_game_objects
end
state=RPG::State.new
state.id=$data_states.size
state.min_turns=state.max_turns=3
$data_states << state
File.open(File.join(output,'battle_effect_reference.tsv'),'w') do |file|
  [[11,0,0.1,5],[12,0,0.1,5],[13,0,7.9,0],[21,state.id,1,0],
   [22,state.id,1,0],[31,2,3,0],[32,2,3,0],[33,2,0,0],
   [34,2,0,0],[41,0,0,0],[42,2,7.9,0],[43,26,0,0],[44,1,0,0]].each do |values|
    target=Game_Actor.new(1)
    target.hp=100
    target.mp=10
    target.tp=0
    target.add_state(state.id) if values[0]==22
    target.add_buff(2,3) if values[0]==33
    target.add_debuff(2,3) if values[0]==34
    target.forget_skill(26) if values[0]==43
    target.result.clear
    item=RPG::Item.new
    effect=RPG::UsableItem::Effect.new(*values)
    before_atk=target.atk
    target.item_effect_apply(target,item,effect)
    target.item_global_effect_apply(effect)
    file.puts [values[0],target.hp,target.mp,target.tp,target.result.hp_damage,
      target.result.mp_damage,target.result.tp_damage,target.result.success,
      target.state?(state.id),target.instance_variable_get(:@buffs)[2],
      target.atk-before_atk,target.skill_learn?($data_skills[26]),
      $game_temp.common_event_reserved?].join("\t")
    $game_temp.clear_common_event
    file.flush
  end
end
File.open(File.join(output,'battle_effect_limits.tsv'),'w') do |file|
  [[11,0,0,0],[12,0,0,0],[13,0,0,0],[21,state.id,0,0],[22,state.id,0,0]].each do |values|
    target=Game_Actor.new(1)
    target.hp=100
    target.mp=10
    target.tp=0
    target.add_state(state.id) if values[0]==22
    target.result.clear
    target.item_effect_apply(target,RPG::Item.new,RPG::UsableItem::Effect.new(*values))
    file.puts ['zero',values[0],target.hp,target.mp,target.tp,target.state?(state.id),target.result.success].join("\t")
  end
  actor=Game_Actor.new(1)
  item=RPG::Item.new
  item.id=$data_items.size
  $data_items << item
  $game_party.gain_item(item,2)
  [true,false].each do |consumable|
    item.consumable=consumable
    actor.use_item(item)
    file.puts ['consume',consumable,$game_party.item_number(item)].join("\t")
  end
  [false,true].each do |battle|
    $game_party.instance_variable_set(:@in_battle,battle)
    [0,1,2,3].each do |occasion|
      item.occasion=occasion
      file.puts ['occasion',battle,occasion,actor.usable?(item)].join("\t")
    end
  end
  $game_party.instance_variable_set(:@in_battle,false)
  skill=RPG::Skill.new
  skill.mp_cost=9
  skill.tp_cost=7
  actor.mp=8
  actor.tp=6
  file.puts ['cost-insufficient',actor.skill_cost_payable?(skill)].join("\t")
  actor.mp=10
  actor.tp=10
  actor.use_item(skill)
  file.puts ['cost-paid',actor.mp,actor.tp].join("\t")
  $game_party.lose_item(item,99)
  $data_items.pop
  $game_party.setup_starting_members
  $game_party.on_battle_start
  $game_troop.setup(1)
  event=RPG::CommonEvent.new
  event.id=$data_common_events.size
  variable_id=$data_system.variables.size
  $data_system.variables << 'Effect event counter'
  event.list=[RPG::EventCommand.new(122,0,[variable_id,variable_id,0,0,7]),
    RPG::EventCommand.new(230,0,[3]),
    RPG::EventCommand.new(122,0,[variable_id,variable_id,1,0,5]),RPG::EventCommand.new]
  $data_common_events << event
  item=RPG::Skill.new
  item.effects=[RPG::UsableItem::Effect.new(44,event.id,0,0)]
  actor.use_item(item)
  7.times do |frame|
    $game_troop.setup_battle_event
    $game_troop.interpreter.update
    file.puts ['common-event',frame,$game_temp.common_event_reserved?,
      $game_troop.interpreter.running?,$game_variables[variable_id]].join("\t")
    file.flush
  end
  $data_common_events.pop
  $data_system.variables.pop
  $game_variables[variable_id]=0
  $game_party.on_battle_end
end
$data_states.pop
File.open(File.join(output,'battle_scope_reference.tsv'),'w') do |file|
  $game_party.setup_starting_members
  $game_party.add_actor(2)
  $game_party.add_actor(3)
  $game_party.on_battle_start
  $game_troop.setup(1)
  $game_troop.members.drop(1).each { |enemy| enemy.hp=0 }
  subject=$game_party.members[0]
  $game_party.members[1].hp=0
  skill=RPG::Skill.new
  skill.id=$data_skills.size
  $data_skills << skill
  (0..11).each do |scope|
    skill.scope=scope
    action=Game_Action.new(subject)
    action.set_skill(skill.id)
    action.target_index=1
    targets=action.make_targets
    names=targets.map { |target| target.actor? ? 'A'+target.id.to_s : 'E'+target.index.to_s }
    file.puts [scope,names.join(','),skill.need_selection?,skill.for_dead_friend?].join("\t")
    file.flush
  end
  $data_skills.pop
  $game_party.members.each { |actor| actor.recover_all }
  $game_party.on_battle_end
end
exit unless $battle_effect_host
