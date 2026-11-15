Audio.bgm_play('F:/Softwares/RPG Maker VX Ace/RTP/Audio/BGM/Theme1.ogg',80,100)
120.times { Graphics.update }
Audio.bgm_stop
Audio.se_play('F:/Softwares/RPG Maker VX Ace/RTP/Audio/SE/Absorb1.ogg',80,100)
120.times { Graphics.update }
Audio.me_play('E:/Projects/RGSS-Godot/tests/fixtures/audio/tone.ogg',80,100)
120.times { Graphics.update }
File.open('midi_me_signal_events.tsv','w') { |file| file.puts "audio-control-complete\t#{Time.now.to_f}" }
exit
