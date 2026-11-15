# D07 menu operations: shared stock-scene/data fixture for original RGSS300 and Godot.
# The Godot runner sets $d07_host, drives real InputEventKey events through the stock
# scenes, and calls check/record helpers here. The original branch has no synthetic
# key injection; it records the same data operations and no-input scene states.
module D07Menu
  def self.prepare(output)
    @output = output
    @file = File.open(File.join(output, 'menu_operations_reference.tsv'), 'w')
    @scene_file = File.open(File.join(output, 'menu_operations_scenes.tsv'), 'w')
    @skill_variance = $data_skills[26].damage.variance
    setup_game
  end

  def self.close
    @file.close if @file
    @scene_file.close if @scene_file
    @file = nil
    @scene_file = nil
  end

  def self.setup_game
    DataManager.setup_new_game
    $game_party.add_actor(2)
    $game_party.add_actor(3)
    $game_party.add_actor(4)
    $game_actors[4].learn_skill(26)
    $data_skills[26].damage.variance = 0
    reset_party
  end

  def self.reset_party
    $game_actors[1].init_equips($data_actors[1].equips)
    $game_party.init_all_items
    $game_party.gain_item($data_items[1], 3)
    $game_party.gain_item($data_weapons[2], 1)
    $game_party.gain_item($data_armors[2], 1)
    $game_party.instance_variable_set(:@actors, [1, 2, 3, 4])
    [1, 2, 3, 4].each { |id| $game_actors[id].recover_all }
    $game_party.menu_actor = $game_actors[1]
    $game_party.target_actor = $game_actors[1]
    $game_party.last_item.object = nil
    $game_actors[4].last_skill.object = nil
  end

  def self.flag(value)
    value ? 1 : 0
  end

  def self.equip_ids(actor)
    actor.equips.map { |item| item ? item.id : 0 }
  end

  def self.counts
    [$game_party.item_number($data_weapons[1]), $game_party.item_number($data_weapons[2]),
     $game_party.item_number($data_armors[1]), $game_party.item_number($data_armors[2]),
     $game_party.item_number($data_armors[46])]
  end

  def self.record(key, values)
    line = key + "\t" + values.join(',')
    @file.puts(line)
  end

  def self.record_scene(key, values)
    line = key + "\t" + values.join(',')
    @scene_file.puts(line)
  end

  def self.data_item_use
    reset_party
    actor = $game_actors[1]
    item = $data_items[1]
    actor.hp = 100
    before_hp = actor.hp
    before_count = $game_party.item_number(item)
    user = $game_party.movable_members.max_by { |member| member.pha }
    $game_party.last_item.object = item
    user.use_item(item)
    actor.item_apply(user, item)
    record('data.item_use', [before_hp, actor.hp, before_count, $game_party.item_number(item),
                             $game_party.last_item.object.id])
  end

  def self.data_skill_use
    reset_party
    caster = $game_actors[4]
    target = $game_actors[2]
    skill = $data_skills[26]
    caster.mp = caster.mmp
    target.hp = 100
    before_mp = caster.mp
    before_hp = target.hp
    caster.last_skill.object = skill
    $game_party.target_actor = target
    caster.use_item(skill)
    target.item_apply(caster, skill)
    record('data.skill_use', [before_mp, caster.mp, before_hp, target.hp,
                              $game_party.target_actor.id, caster.last_skill.object.id])
  end

  def self.data_equip_change
    reset_party
    actor = $game_actors[1]
    actor.change_equip(0, $data_weapons[2])
    record('data.equip_change', equip_ids(actor) + counts)
  end

  def self.data_equip_optimize
    reset_party
    actor = $game_actors[1]
    actor.change_equip(0, $data_weapons[2])
    actor.optimize_equipments
    record('data.equip_optimize', equip_ids(actor) + counts)
  end

  def self.data_equip_clear
    reset_party
    actor = $game_actors[1]
    actor.change_equip(0, $data_weapons[2])
    actor.optimize_equipments
    actor.clear_equipments
    record('data.equip_clear', equip_ids(actor) + counts)
  end

  def self.data_formation_swap
    reset_party
    before = $game_party.members.map { |actor| actor.id }
    $game_party.swap_order(1, 2)
    after = $game_party.members.map { |actor| actor.id }
    record('data.formation_swap', before + after)
  end

  def self.data_actor_nav
    reset_party
    $game_party.menu_actor = $game_actors[1]
    ids = [$game_party.menu_actor.id]
    $game_party.menu_actor_next
    ids << $game_party.menu_actor.id
    $game_party.menu_actor_next
    ids << $game_party.menu_actor.id
    $game_party.menu_actor_prev
    ids << $game_party.menu_actor.id
    record('data.actor_nav', ids)
  end

  def self.data_ops
    data_item_use
    data_skill_use
    data_equip_change
    data_equip_optimize
    data_equip_clear
    data_formation_swap
    data_actor_nav
  end

  def self.read_scene(key)
    scene = SceneManager.scene
    case key
    when 'scene.menu'
      command = scene.instance_variable_get(:@command_window)
      status = scene.instance_variable_get(:@status_window)
      record_scene(key, [command.index, flag(command.active), flag(command.open?),
                         command.item_max, command.current_symbol.to_s,
                         status.index, flag(status.active), flag(status.open?),
                         status.item_max])
    when 'scene.item'
      category = scene.instance_variable_get(:@category_window)
      items = scene.instance_variable_get(:@item_window)
      record_scene(key, [category.index, flag(category.active), category.current_symbol.to_s,
                         items.index, flag(items.active), items.item_max,
                         items.item ? items.item.id : 0])
    when 'scene.skill'
      command = scene.instance_variable_get(:@command_window)
      items = scene.instance_variable_get(:@item_window)
      record_scene(key, [command.index, flag(command.active), command.item_max,
                         command.current_symbol.to_s, items.index, flag(items.active),
                         items.item_max])
    when 'scene.equip'
      command = scene.instance_variable_get(:@command_window)
      slot = scene.instance_variable_get(:@slot_window)
      items = scene.instance_variable_get(:@item_window)
      record_scene(key, [command.index, flag(command.active), command.item_max,
                         command.current_symbol.to_s, slot.index, flag(slot.active),
                         slot.item_max, items.index, flag(items.active), items.item_max])
    when 'scene.status'
      status = scene.instance_variable_get(:@status_window)
      record_scene(key, [status.instance_variable_get(:@actor).id, flag(status.active),
                         status.index])
    else
      raise 'unknown scene key ' + key
    end
  end

  def self.original_scene_states
    SceneManager.instance_variable_set(:@background_bitmap, Bitmap.new(Graphics.width, Graphics.height))
    original_scene('scene.menu', Scene_Menu, 1)
    original_scene('scene.item', Scene_Item, 1)
    original_scene('scene.skill', Scene_Skill, 4)
    original_scene('scene.equip', Scene_Equip, 1)
    original_scene('scene.status', Scene_Status, 1)
    SceneManager.goto(Scene_Map)
  end

  def self.original_scene(key, scene_class, actor_id)
    reset_party
    $game_party.menu_actor = $game_actors[actor_id]
    Window_MenuCommand.init_command_position if scene_class == Scene_Menu
    SceneManager.goto(scene_class)
    scene = SceneManager.scene
    scene.start
    scene.post_start
    20.times { scene.update }
    read_scene(key)
    scene.pre_terminate
    scene.terminate
  end

  def self.restore
    $data_skills[26].damage.variance = @skill_variance
    reset_party
    $game_party.instance_variable_set(:@actors, [1])
    $game_party.instance_variable_set(:@menu_actor_id, 0)
    $game_party.instance_variable_set(:@target_actor_id, 0)
    $game_player.refresh
    $game_map.need_refresh = true
  end
end

unless $d07_host
  output = Dir.pwd
  begin
    Dir.chdir(TestPaths.game)
    module Cache
      class << self
        alias d07_original_load_bitmap load_bitmap
        def load_bitmap(folder, filename, hue = 0)
          unless filename.empty? || File.exist?(folder + filename + '.png')
            folder = TestPaths.rtp(folder)
          end
          d07_original_load_bitmap(folder, filename, hue)
        end
      end
    end
    module Audio
      class << self
        alias d07_original_se_play se_play
        def se_play(filename, volume = 100, pitch = 100)
          filename = TestPaths.rtp(filename) unless File.exist?(filename + '.ogg') || File.exist?(filename + '.wav')
          d07_original_se_play(filename, volume, pitch)
        end
      end
    end
    DataManager.init
    D07Menu.prepare(output)
    D07Menu.data_ops
    D07Menu.original_scene_states
    D07Menu.close
    File.open(File.join(output, 'd07-menu-original-complete.txt'), 'w') { |file| file.puts('D07_MENU_ORIGINAL_COMPLETE') }
  rescue Exception => error
    File.open(File.join(output, 'd07-menu-original-error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  end
  exit
end
