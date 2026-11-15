output = $rgss_compat_output || '.'
saved = [$game_map, $game_message, $game_system, $data_system, $rmva_project_base_path]
begin
  $rmva_project_base_path = $event_audio_base if $event_audio_base
  $data_system = RPG::System.new
  $game_map = Game_Map.new
  $game_message = Game_Message.new
  $game_system = Game_System.new
  cases = [
    ['bgm-play', 241, [RPG::BGM.new('tone.ogg', 80, 110)]],
    ['bgm-save', 243, []], ['bgm-replace', 241, [RPG::BGM.new('tone.ogg', 60, 90)]],
    ['bgm-replay', 244, []], ['bgm-fade', 242, [1]],
    ['bgs-play', 245, [RPG::BGS.new('tone.ogg', 70, 120)]],
    ['bgs-fade', 246, [1]], ['me-play', 249, [RPG::ME.new('tone.ogg', 80, 100)]],
    ['se-play', 250, [RPG::SE.new('tone.ogg', 90, 100)]], ['se-stop', 251, []],
    ['bgm-stop', 241, [RPG::BGM.new]], ['bgs-stop', 245, [RPG::BGS.new]]
  ]
  File.open(File.join(output, 'event_audio_reference.tsv'), 'w') do |file|
    cases.each do |name, code, parameters|
      interpreter = Game_Interpreter.new
      interpreter.setup([RPG::EventCommand.new(code, 0, parameters), RPG::EventCommand.new])
      count = 0
      while interpreter.running?
        raise "audio event hung: #{name}" if count >= 10
        interpreter.update
        count += 1
      end
      bgm = RPG::BGM.last
      bgs = RPG::BGS.last
      file.puts([name, count, bgm.name, bgm.volume, bgm.pitch,
        bgs.name, bgs.volume, bgs.pitch].join("\t"))
      file.flush
    end
  end
rescue Exception => error
  File.open(File.join(output, 'event_audio_error.txt'), 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  raise if $rgss_compat_output
ensure
  Audio.bgm_stop
  Audio.bgs_stop
  Audio.me_stop
  Audio.se_stop
  $game_map, $game_message, $game_system, $data_system, $rmva_project_base_path = saved
end
exit unless $rgss_compat_output
