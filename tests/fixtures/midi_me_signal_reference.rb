output = $rgss_compat_output || '.'
midi = TestPaths.fixture('midi-reference.mid')
tone = TestPaths.fixture('audio/tone.ogg')
Graphics.frame_rate = 60
File.open(File.join(output, 'midi_me_signal_events.tsv'), 'w') do |file|
  mark = proc do |name|
    file.puts [name, Time.now.to_f].join("\t")
    file.flush
  end
  mark.call('begin')
  120.times { Graphics.update }
  Audio.setup_midi
  Audio.bgm_play(midi, 80, 100)
  mark.call('midi-start')
  120.times { Graphics.update }
  Audio.me_play(tone, 80, 25)
  mark.call('me-start')
  240.times { Graphics.update }
  mark.call('me-late')
  Audio.bgm_stop
  mark.call('bgm-stop')
  120.times { Graphics.update }
  mark.call('end')
end
exit unless $midi_me_signal_host
