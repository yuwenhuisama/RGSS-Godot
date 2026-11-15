require 'audio'
require 'graphics'
root = Unity.rmva_project_path
Unity.register_update_fiber(Fiber.new do
  Audio.bgm_play(File.join(root, 'tone.wma'), 0)
  File.open(File.join(root, 'audio-ready'), 'w') { |file| file.write('ready') }
  until File.exist?(File.join(root, 'capture-start'))
    Graphics.update
  end
  Audio.bgm_play(File.join(root, 'tone.wma'), 80)
  180.times { Graphics.update }
  Audio.bgm_stop
  120.times { Graphics.update }
  Audio.bgm_play(File.join(root, 'midi-reference.mid'), 80)
  180.times { Graphics.update }
  Audio.bgm_stop
  120.times { Graphics.update }
  puts 'MACOS_AUDIO_SIGNAL_SEQUENCE_PASS'
  File.open(File.join(root, 'sequence-finished'), 'w') { |file| file.write('complete') }
  until File.exist?(File.join(root, 'capture-finished'))
    Graphics.update
  end
end)
