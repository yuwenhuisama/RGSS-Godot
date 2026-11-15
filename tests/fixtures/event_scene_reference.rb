output = $rgss_compat_output || '.'
saved = [$game_map, $game_party, $game_message, $data_system, $data_actors,
  SceneManager.scene, SceneManager.instance_variable_get(:@stack)]
begin
  $data_system = RPG::System.new
  $data_actors = [nil, RPG::Actor.new]
  $data_actors[1].id = 1
  $game_map = Game_Map.new
  $game_party = Game_Party.new
  $game_message = Game_Message.new
  cases = [
    ['menu', [[351, []]]], ['save', [[352, []]]],
    ['gameover', [[353, []]]], ['title', [[354, []]]],
    ['shop', [[302, [0, 1, 0, 0, false]], [605, [1, 2, 1, 75]]]],
    ['shop-buy-only', [[302, [2, 3, 1, 120, true]]]],
    ['name', [[303, [1, 8]]]], ['name-missing', [[303, [99, 8]]]],
    ['battle-menu-blocked', [[351, []]]], ['battle-save-blocked', [[352, []]]],
    ['battle-shop-blocked', [[302, [0, 1, 0, 0, false]]]],
    ['battle-name-blocked', [[303, [1, 8]]]]
  ]
  File.open(File.join(output, 'event_scene_reference.tsv'), 'w') do |file|
    cases.each do |name, commands|
      $game_party = Game_Party.new
      $game_party.on_battle_start if name.start_with?('battle-')
      SceneManager.instance_variable_set(:@scene, Scene_Map.new)
      SceneManager.instance_variable_set(:@stack, [])
      list = commands.map { |code, params| RPG::EventCommand.new(code, 0, params) }
      list << RPG::EventCommand.new
      interpreter = Game_Interpreter.new
      interpreter.setup(list)
      3.times do |frame|
        interpreter.update
        scene = SceneManager.scene
        values = [name, frame, interpreter.running?, scene.class.to_s,
          SceneManager.instance_variable_get(:@stack).map { |item| item.class.to_s }.join(','),
          scene.instance_variable_get(:@goods).inspect,
          scene.instance_variable_get(:@purchase_only).inspect,
          scene.instance_variable_get(:@actor_id).inspect,
          scene.instance_variable_get(:@max_char).inspect]
        file.puts(values.join("\t"))
        file.flush
      end
      raise "scene event did not finish: #{name}" if interpreter.running?
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_scene_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  $game_map, $game_party, $game_message, $data_system, $data_actors = saved[0, 5]
  SceneManager.instance_variable_set(:@scene, saved[5])
  SceneManager.instance_variable_set(:@stack, saved[6])
end
exit unless $rgss_compat_output
