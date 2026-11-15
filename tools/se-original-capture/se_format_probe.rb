absolute_ogg = TestPaths.fixture('audio/tone.ogg')
absolute_wav = TestPaths.fixture('audio/tone.wav')
absolute_wav44 = File.join(TestPaths.repo('.omo/compatibility-run-tmp/e08-se-original'), 'tone44.wav')
events = File.open('se_format_events.tsv', 'w')

def stamp(events, name, extra = nil)
  events.puts [name, format('%.6f', Time.now.to_f), extra].compact.join("\t")
  events.flush
end

def attempt(events, label, kind, filename)
  result = kind == :se ? Audio.se_play(filename, 100, 100) : Audio.bgm_play(filename, 100, 100)
  stamp(events, label, result.inspect)
  30.times { Graphics.update }
  kind == :se ? Audio.se_stop : Audio.bgm_stop
  30.times { Graphics.update }
end

Graphics.frame_rate = 60
stamp(events, 'BEGIN')
30.times { Graphics.update }
begin
  attempt(events, 'SE_OGG_ABS', :se, absolute_ogg)
  attempt(events, 'SE_OGG_REL', :se, 'Audio/SE/tone')
  attempt(events, 'SE_WAV_ABS', :se, absolute_wav)
  attempt(events, 'SE_WAV_REL', :se, 'Audio/SE/tone.wav')
  attempt(events, 'SE_WAV44_ABS', :se, absolute_wav44)
  attempt(events, 'SE_WAV44_REL', :se, 'Audio/SE/tone44.wav')
  attempt(events, 'BGM_OGG_ABS', :bgm, absolute_ogg)
  stamp(events, 'EXIT')
rescue => error
  stamp(events, 'ERROR', "#{error.class}: #{error.message}")
  raise
ensure
  events.close
end
exit 0
