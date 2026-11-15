output = $rgss_compat_output || '.'
midi = $midi_me_midi || 'midi-reference.mid'
tone = $midi_me_tone || 'tone.ogg'
Graphics.frame_rate = 60
Audio.setup_midi
File.open(File.join(output, 'midi_me_signal_events.tsv'), 'w') do |file|
  mark = proc do |name|
    file.puts [name, Time.now.to_f].join("\t")
    file.flush
  end
  120.times { Graphics.update }
  %w[stop fade stopped-bgm].each do |mode|
    Audio.bgm_play(midi, 80, 100)
    mark.call(mode + '-midi')
    120.times { Graphics.update }
    Audio.me_play(tone, 80, 25)
    mark.call(mode + '-me')
    60.times { Graphics.update }
    if mode == 'stop'
      Audio.me_stop
    elsif mode == 'fade'
      Audio.me_fade(300)
    else
      Audio.bgm_stop
      Audio.me_stop
    end
    mark.call(mode + '-release')
    120.times { Graphics.update }
    if mode == 'fade'
      Audio.me_stop
      mark.call('fade-explicit-stop')
      120.times { Graphics.update }
    end
    Audio.bgm_stop
    Audio.me_stop
    mark.call(mode + '-end')
    60.times { Graphics.update }
  end
end
exit unless $midi_me_signal_host
