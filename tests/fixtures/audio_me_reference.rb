output = $rgss_compat_output || '.'
bgm = $audio_me_bgm || 'F:/Softwares/RPG Maker VX Ace/RTP/Audio/BGM/Theme1.ogg'
me = $audio_me_sound || 'E:/Projects/RGSS-Godot/tests/fixtures/audio/tone.ogg'
Graphics.frame_rate = 60
File.open(File.join(output, 'audio_me_reference.tsv'), 'w') do |file|
  Audio.bgm_play(bgm, 80, 100)
  60.times { Graphics.update }
  file.puts ['before-me', Audio.bgm_pos].join("\t")
  file.flush
  Audio.me_play(me, 80, 50)
  [1, 10, 20, 60, 60].each do |count|
    count.times { Graphics.update }
    file.puts ['after-me', count, Audio.bgm_pos].join("\t")
    file.flush
  end
  Audio.bgm_stop
  Audio.me_play(me, 80, 100)
  90.times { Graphics.update }
  file.puts ['stopped-bgm-after-me', Audio.bgm_pos].join("\t")
  file.flush
  Audio.me_stop
end
File.open(File.join(output, 'audio_me_end_reference.tsv'), 'w') do |file|
  [:stop, :fade].each do |ending|
    Audio.bgm_play(bgm, 80, 100)
    60.times { Graphics.update }
    Audio.me_play(me, 80, 25)
    10.times { Graphics.update }
    paused = Audio.bgm_pos
    ending == :stop ? Audio.me_stop : Audio.me_fade(100)
    30.times { Graphics.update }
    file.puts [ending, paused, Audio.bgm_pos].join("\t")
    file.flush
    150.times { Graphics.update }
    file.puts [ending.to_s + '-late', paused, Audio.bgm_pos].join("\t")
    file.flush
    Audio.me_stop
    Audio.bgm_stop
  end
end
exit unless $audio_me_host
