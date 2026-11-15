Audio.bgm_play(TestPaths.rtp('Audio/BGM/Theme1.ogg'),80,100)
120.times { Graphics.update }
Audio.bgm_stop
Audio.se_play(TestPaths.rtp('Audio/SE/Absorb1.ogg'),80,100)
120.times { Graphics.update }
Audio.me_play(TestPaths.fixture('audio/tone.ogg'),80,100)
120.times { Graphics.update }
File.open('midi_me_signal_events.tsv','w') { |file| file.puts "audio-control-complete\t#{Time.now.to_f}" }
exit
