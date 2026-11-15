output = $rgss_compat_output || '.'
saved = [$game_map, $game_party, $game_message, $data_system, $data_tilesets, $data_animations]
sprite = nil
balloon = nil
begin
  $data_system = RPG::System.new
  $data_tilesets = [nil, RPG::Tileset.new]
  $game_map = Game_Map.new
  $game_map.instance_variable_set(:@map, RPG::Map.new(24, 20))
  $game_map.instance_variable_set(:@map_id, 1)
  $game_map.instance_variable_set(:@tileset_id, 1)
  $game_map.instance_variable_set(:@tile_events, [])
  $game_party = Game_Party.new
  $game_message = Game_Message.new
  animation = RPG::Animation.new
  animation.frame_max = 3
  animation.frames = Array.new(3) { RPG::Animation::Frame.new }
  $data_animations = [nil, animation]
  Cache.instance_variable_set(:@cache, {}) unless Cache.instance_variable_get(:@cache)
  cache = Cache.instance_variable_get(:@cache)
  key = DataManager.respond_to?(:__get_rtp_path__) ? DataManager.__get_rtp_path__('Graphics/System/') + 'Balloon.png' : 'Graphics/System/Balloon'
  old_balloon = cache[key]
  balloon = Bitmap.new(256, 320)
  cache[key] = balloon
  event_data = RPG::Event.new(5, 5)
  event_data.id = 1
  event = Game_Event.new(1, event_data)
  $game_map.instance_variable_set(:@events, {1 => event})
  sprite = Sprite_Character.new(nil, event)
  File.open(File.join(output, 'event_effect_wait_reference.tsv'), 'w') do |file|
    [[212, 'animation'], [213, 'balloon']].each do |code, name|
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(code, 0, [1, 1, true]), RPG::EventCommand.new])
      frame = 0
      while interpreter.running? || frame < 4
        raise "effect wait hung: #{name}" if frame >= 100
        interpreter.update
        file.puts([name, frame, interpreter.running?, event.animation_id, event.balloon_id,
          sprite.animation?].join("\t"))
        file.flush
        sprite.update
        frame += 1
      end
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_effect_wait_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  sprite.dispose if sprite && !sprite.disposed?
  cache[key] = old_balloon if cache && key
  balloon.dispose if balloon && !balloon.disposed?
  $game_map, $game_party, $game_message, $data_system, $data_tilesets, $data_animations = saved
end
exit unless $rgss_compat_output
