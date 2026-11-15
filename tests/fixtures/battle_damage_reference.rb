output = $rgss_compat_output || '.'
unless $battle_damage_host
  DataManager.load_database
  DataManager.create_game_objects
  $game_party.setup_starting_members
end
enemy_data = RPG::Enemy.new
enemy_data.id = $data_enemies.size
enemy_data.params = [500,100,30,20,25,15,10,10]
$data_enemies << enemy_data
user = $game_party.members[0]
skill = RPG::Skill.new
skill.damage.formula = '81.5'
skill.damage.variance = 0
File.open(File.join(output,'battle_damage_reference.tsv'),'w') do |file|
  [1,2,3,4,5,6].each do |damage_type|
    [0,1,2].each do |hit_type|
      [false,true].each do |critical|
        [false,true].each do |guard|
          enemy_data.features = [RPG::BaseItem::Feature.new(11,1,0.5),
            RPG::BaseItem::Feature.new(23,6,0.75),RPG::BaseItem::Feature.new(23,7,1.25),
            RPG::BaseItem::Feature.new(23,2,1.5)]
          enemy_data.features << RPG::BaseItem::Feature.new(62,1,1) if guard
          target = Game_Enemy.new(0,enemy_data.id)
          target.hp=300
          target.mp=60
          user.hp=user.mhp-100
          user.mp=user.mmp-20
          skill.damage.type=damage_type
          skill.damage.element_id=1
          skill.hit_type=hit_type
          target.result.clear
          target.result.critical=critical
          target.make_damage_value(user,skill)
          target.execute_damage(user)
          file.puts [damage_type,hit_type,critical,guard,target.result.hp_damage,
            target.result.mp_damage,target.result.hp_drain,target.result.mp_drain,
            target.hp,target.mp,user.hp,user.mp].join("\t")
          file.flush
        end
      end
    end
  end
end
File.open(File.join(output,'battle_damage_edges_reference.tsv'),'w') do |file|
  [5,6].each do |kind|
    enemy_data.features=[]
    target=Game_Enemy.new(0,enemy_data.id)
    target.hp=7
    target.mp=3
    user.hp=user.mhp-20
    user.mp=user.mmp-10
    skill.damage.type=kind
    skill.damage.formula='100'
    skill.damage.element_id=0
    skill.damage.critical=false
    skill.hit_type=0
    target.make_damage_value(user,skill)
    target.execute_damage(user)
    file.puts ['drain-cap',kind,target.hp,target.mp,target.result.hp_drain,target.result.mp_drain].join("\t")
  end
  enemy_data.features=[RPG::BaseItem::Feature.new(11,1,0.5),RPG::BaseItem::Feature.new(11,2,1.5)]
  target=Game_Enemy.new(0,enemy_data.id)
  saved_actor_features=user.actor.features.dup
  user.actor.features += [RPG::BaseItem::Feature.new(31,1,1),RPG::BaseItem::Feature.new(31,2,1)]
  skill.damage.type=1
  skill.damage.element_id=-1
  file.puts ['attack-elements-max',target.item_element_rate(user,skill)].join("\t")
  user.actor.features=saved_actor_features
  skill.damage.element_id=1
  file.puts ['explicit-element',target.item_element_rate(user,skill)].join("\t")
  enemy_data.features=[RPG::BaseItem::Feature.new(61,0,0),RPG::BaseItem::Feature.new(61,0,1),RPG::BaseItem::Feature.new(61,0,1)]
  target=Game_Enemy.new(0,enemy_data.id)
  target.make_actions
  file.puts ['action-times',target.make_action_times,target.actions.size].join("\t")
  class << target
    attr_accessor :variance_edge
    def rand(limit)
      variance_edge == :low ? 0 : limit-1
    end
  end
  [:low,:high].each do |edge|
    target.variance_edge=edge
    file.puts ['variance-edge',edge,target.apply_variance(100,20),target.apply_variance(-100,20),target.apply_variance(100,0)].join("\t")
  end
  confusion_state=RPG::State.new
  confusion_state.id=$data_states.size
  $data_states << confusion_state
  [1,2,3,4].each do |restriction|
    confusion_state.restriction=restriction
    target=Game_Enemy.new(0,enemy_data.id)
    target.add_state(confusion_state.id)
    target.make_actions
    file.puts ['confusion',restriction,target.confusion?,target.confusion_level,target.movable?,target.actions.size].join("\t")
  end
  action=Game_Action.new(target)
  class << action
    attr_accessor :choice
    def rand(limit); choice; end
  end
  opponents=Object.new
  friends=Object.new
  def opponents.random_target; :opponent; end
  def friends.random_target; :friend; end
  action.define_singleton_method(:opponents_unit) { opponents }
  action.define_singleton_method(:friends_unit) { friends }
  [1,2,3].each do |level|
    confusion_state.restriction=level
    [0,1].each do |choice|
      action.choice=choice
      file.puts ['confusion-target',level,choice,action.confusion_target].join("\t")
    end
  end
  $data_states.pop
end
File.open(File.join(output,'battle_hit_reference.tsv'),'w') do |file|
  enemy_data.features = [RPG::BaseItem::Feature.new(22,1,0.25),
    RPG::BaseItem::Feature.new(22,3,0.4),RPG::BaseItem::Feature.new(22,4,0.5),
    RPG::BaseItem::Feature.new(22,5,0.75),RPG::BaseItem::Feature.new(22,6,0.3)]
  target = Game_Enemy.new(0,enemy_data.id)
  [0,1,2].each do |hit_type|
    skill.hit_type=hit_type
    skill.success_rate=80
    skill.damage.critical=true
    file.puts ['rates',hit_type,target.item_hit(user,skill),target.item_eva(user,skill),
      target.item_cnt(user,skill),target.item_mrf(user,skill),target.item_cri(user,skill)].join("\t")
  end
  [[0,0,0],[1,100,1],[2,100,1],[0,100,0]].each do |hit_type,success,evade|
    enemy_data.features = [RPG::BaseItem::Feature.new(22,1,evade),
      RPG::BaseItem::Feature.new(22,4,evade)]
    target = Game_Enemy.new(0,enemy_data.id)
    target.hp=300
    skill.hit_type=hit_type
    skill.success_rate=success
    skill.scope=1
    skill.damage.type=1
    skill.damage.element_id=0
    skill.damage.critical=false
    skill.damage.formula='10'
    def target.rand(*args); args.empty? ? 0.5 : 0; end
    target.item_apply(user,skill)
    file.puts ['apply',hit_type,success,evade,target.result.used,target.result.missed,
      target.result.evaded,target.result.hp_damage,target.hp].join("\t")
    file.flush
  end
end
File.open(File.join(output,'battle_state_reference.tsv'),'w') do |file|
  state_base=$data_states.size
  [1,2,0].each_with_index do |timing,index|
    state=RPG::State.new
    state.id=state_base+index
    state.auto_removal_timing=timing
    state.min_turns=state.max_turns=2
    state.remove_at_battle_end=(index==2)
    $data_states << state
  end
  enemy_data.features=[]
  target=Game_Enemy.new(0,enemy_data.id)
  3.times { |index| target.add_state(state_base+index) }
  target.add_buff(2,2)
  target.add_buff(2,1)
  target.add_buff(2,1)
  3.times do |turn|
    ['before','turn-end','action-end'].each do |phase|
      target.on_turn_end if phase=='turn-end'
      target.on_action_end if phase=='action-end'
      file.puts ['timeline',turn,phase,target.states.map { |state| state.id-state_base }.join(','),
        target.instance_variable_get(:@state_turns).values.join(','),
        target.instance_variable_get(:@buffs)[2],target.instance_variable_get(:@buff_turns)[2]].join("\t")
    end
  end
  target.on_battle_end
  file.puts ['battle-end',target.states.size,target.instance_variable_get(:@buffs)[2]].join("\t")
  target.add_buff(2,3)
  target.add_debuff(2,2)
  file.puts ['opposite-buff',target.instance_variable_get(:@buffs)[2],target.instance_variable_get(:@buff_turns)[2]].join("\t")
  target.add_state(1)
  file.puts ['death',target.hp,target.death_state?,target.instance_variable_get(:@buffs)[2]].join("\t")
  target.remove_state(1)
  file.puts ['revive',target.hp,target.death_state?].join("\t")
  [false,true].each do |slip_death|
    $data_system.opt_slip_death=slip_death
    enemy_data.features=[RPG::BaseItem::Feature.new(22,7,-0.1),
      RPG::BaseItem::Feature.new(22,8,0.2),RPG::BaseItem::Feature.new(22,9,0.1)]
    target=Game_Enemy.new(0,enemy_data.id)
    target.hp=20
    target.mp=50
    target.tp=0
    target.regenerate_all
    file.puts ['regenerate',slip_death,target.hp,target.mp,target.tp,target.result.hp_damage,target.result.mp_damage].join("\t")
  end
  3.times { $data_states.pop }
  state=RPG::State.new
  state.id=$data_states.size
  state.min_turns=state.max_turns=2
  state.remove_by_damage=true
  $data_states << state
  [0,100].each do |chance|
    state.chance_by_damage=chance
    enemy_data.features=[]
    target=Game_Enemy.new(0,enemy_data.id)
    target.add_state(state.id)
    target.remove_states_by_damage
    file.puts ['damage-removal',chance,target.state?(state.id)].join("\t")
  end
  enemy_data.features=[RPG::BaseItem::Feature.new(14,state.id,1)]
  target=Game_Enemy.new(0,enemy_data.id)
  target.add_state(state.id)
  file.puts ['resist',target.state?(state.id)].join("\t")
  enemy_data.features=[]
  target=Game_Enemy.new(0,enemy_data.id)
  target.add_state(state.id)
  target.remove_state(state.id)
  target.add_state(state.id)
  file.puts ['removed-result-blocks-readd',target.state?(state.id)].join("\t")
  target.result.clear
  target.add_state(state.id)
  file.puts ['clear-result-allows-readd',target.state?(state.id)].join("\t")
  restrictive=RPG::State.new
  restrictive.id=$data_states.size
  restrictive.restriction=4
  $data_states << restrictive
  state.remove_by_restriction=true
  target.make_actions
  target.add_state(restrictive.id)
  file.puts ['restriction',target.state?(state.id),target.state?(restrictive.id),target.movable?,target.instance_variable_get(:@actions).size].join("\t")
  target.add_state(state.id)
  file.puts ['restrict-readd',target.state?(state.id)].join("\t")
  enemy_data.features=[]
  target=Game_Enemy.new(0,enemy_data.id)
  state.remove_by_restriction=false
  state.auto_removal_timing=2
  target.add_state(state.id)
  target.update_state_turns
  target.add_state(state.id)
  file.puts ['state-reapply',target.instance_variable_get(:@state_turns)[state.id],target.result.added_states.count(state.id)].join("\t")
  target.add_state(1)
  target.result.clear
  target.add_state(state.id)
  file.puts ['dead-state-reject',target.state?(state.id),target.state?(1)].join("\t")
  target=Game_Enemy.new(0,enemy_data.id)
  target.add_state(state.id)
  enemy_data.features=[RPG::BaseItem::Feature.new(14,state.id,1)]
  target.refresh
  file.puts ['refresh-resist-removal',target.state?(state.id)].join("\t")
  enemy_data.features=[]
  actor=$game_actors[1]
  actor.recover_all
  state.remove_by_walking=true
  state.steps_to_remove=2
  actor.add_state(state.id)
  2.times do |step|
    actor.update_state_steps(state)
    file.puts ['walking-removal',step+1,actor.state?(state.id),actor.instance_variable_get(:@state_steps)[state.id]].join("\t")
  end
  actor.recover_all
  2.times { $data_states.pop }
end
$data_enemies.pop
user.recover_all
exit unless $battle_damage_host
