require 'audio'
require 'graphics'
root = Unity.rmva_project_path
fiber = Fiber.new do
  Audio.setup_midi
  ['midi-reference.mid','midi-reference-sysex.mid','midi-reference-smpte.mid'].each do |name|
    Audio.bgm_play(File.join(root,'probes',name),80,100,8192)
    30.times { Graphics.update }
    raise 'MIDI public position differs' unless Audio.bgm_pos == 0
    Audio.bgm_stop
  end
  puts 'LINUX_RELEASE_MIDI_PASS'
  loop { Graphics.update }
end
Unity.register_update_fiber(fiber)
