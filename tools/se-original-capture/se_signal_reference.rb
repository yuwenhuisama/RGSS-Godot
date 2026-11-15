tone = 'E:/Projects/RGSS-Godot/tests/fixtures/audio/tone.wav'
events = File.open('se_signal_events.tsv', 'w')

def stamp(events, name, extra = nil)
  events.puts [name, format('%.6f', Time.now.to_f), extra].compact.join("\t")
  events.flush
end

Graphics.frame_rate = 60
stamp(events, 'BEGIN')
begin
  30.times { Graphics.update }
  stamp(events, 'SE_START')
  120.times do |index|
    if index % 12 == 0
      Audio.se_play(tone, 100, 100)
      Audio.se_play(tone, 100, 150)
    end
    Graphics.update
  end
  Audio.se_stop
  stamp(events, 'SE_STOP')
  180.times { Graphics.update }
  stamp(events, 'EXIT')
rescue => error
  stamp(events, 'ERROR', "#{error.class}: #{error.message}")
  raise
ensure
  events.close
end
exit 0
