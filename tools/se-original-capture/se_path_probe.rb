absolute_tone = TestPaths.fixture('audio/tone.wav')
events = File.open('se_path_events.tsv', 'w')

def stamp(events, name, extra = nil)
  events.puts [name, format('%.6f', Time.now.to_f), extra].compact.join("\t")
  events.flush
end

def attempt(events, label, kind, filename)
  result = kind == :se ? Audio.se_play(filename, 100, 100) : Audio.bgm_play(filename, 100, 100)
  stamp(events, label, result.inspect)
  24.times { Graphics.update }
  kind == :se ? Audio.se_stop : Audio.bgm_stop
  30.times { Graphics.update }
end

Graphics.frame_rate = 60
stamp(events, 'BEGIN')
30.times { Graphics.update }
begin
  attempt(events, 'TRY_SE_ABS_EXT', :se, absolute_tone)
  attempt(events, 'TRY_SE_ABS_NOEXT', :se, absolute_tone.sub(/\.wav\z/, ''))
  attempt(events, 'TRY_SE_REL_EXT', :se, 'Audio/SE/tone.wav')
  attempt(events, 'TRY_SE_REL_NOEXT', :se, 'Audio/SE/tone')
  attempt(events, 'TRY_BGM_ABS_EXT', :bgm, absolute_tone)
  attempt(events, 'TRY_BGM_REL_NOEXT', :bgm, 'Audio/BGM/tone')
  stamp(events, 'EXIT')
rescue => error
  stamp(events, 'ERROR', "#{error.class}: #{error.message}")
  raise
ensure
  events.close
end
exit 0
