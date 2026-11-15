output = $rgss_compat_output || '.'
Graphics.frame_rate = 60
File.open(File.join(output, 'audio_position_reference.tsv'), 'w') do |file|
  ['wav', 'ogg', 'wma'].each do |extension|
    path = TestPaths.fixture('audio/tone.' + extension)
    Audio.bgm_stop
    Audio.bgm_play(path, 80, 100, 0)
    3.times do |step|
      4.times { Graphics.update }
      file.puts [extension, 'advance', step, Audio.bgm_pos].join("\t")
      file.flush
    end
    Audio.bgm_stop
    file.puts [extension, 'stopped', Audio.bgm_pos].join("\t")
    Audio.bgm_play(path, 80, 100, 4096)
    Graphics.update
    file.puts [extension, 'seek4096', Audio.bgm_pos].join("\t")
    file.flush
    Audio.bgm_stop
  end
  Audio.bgm_play(TestPaths.rtp('Audio/BGM/Theme1.ogg'), 80, 100, 0)
  60.times { Graphics.update }
  3.times do |step|
    60.times { Graphics.update }
    file.puts ['ogg-stereo44100', 'advance', step, Audio.bgm_pos].join("\t")
    file.flush
  end
  Audio.bgm_stop
end
exit unless $audio_position_host
