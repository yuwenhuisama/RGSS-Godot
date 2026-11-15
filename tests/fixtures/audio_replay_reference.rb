output = $rgss_compat_output || '.'
tone = $audio_replay_tone || TestPaths.fixture('audio/tone.ogg')
Graphics.frame_rate = 60
File.open(File.join(output, 'audio_replay_reference.tsv'), 'w') do |file|
  Audio.bgm_play(tone, 80, 100)
  12.times { Graphics.update }
  file.puts ['initial', Audio.bgm_pos].join("\t")
  Audio.bgm_play(tone, 40, 100)
  file.puts ['same-file-volume', Audio.bgm_pos].join("\t")
  12.times { Graphics.update }
  file.puts ['same-file-later', Audio.bgm_pos].join("\t")
  Audio.bgm_play(tone, 80, 100, 4096)
  file.puts ['same-file-seek', Audio.bgm_pos].join("\t")
  Audio.bgm_play(tone, 80, 120)
  file.puts ['same-file-pitch', Audio.bgm_pos].join("\t")
  Audio.bgs_play(tone, 60, 100)
  12.times { Graphics.update }
  file.puts ['bgm-and-bgs', Audio.bgm_pos, Audio.bgs_pos].join("\t")
  Audio.bgs_play(tone, 40, 100, 4096)
  file.puts ['bgs-same-file', Audio.bgm_pos, Audio.bgs_pos].join("\t")
  Audio.bgs_stop
  file.puts ['bgs-stop', Audio.bgm_pos, Audio.bgs_pos].join("\t")
  Audio.bgm_stop
  Audio.bgm_play(tone, 80, 100, 4096)
  Graphics.update
  file.puts ['seek', Audio.bgm_pos].join("\t")
  Audio.bgm_fade(100)
  60.times { Graphics.update }
  file.puts ['bgm-fade', Audio.bgm_pos].join("\t")
  file.flush
  Audio.bgm_stop
end
File.open(File.join(output,'audio_fade_replace_reference.tsv'),'w') do |file|
  Audio.bgm_play(tone,80,100)
  Audio.bgm_fade(500)
  6.times { Graphics.update }
  Audio.bgm_stop
  Audio.bgm_play(tone,80,100)
  42.times { Graphics.update }
  before=Audio.bgm_pos
  12.times { Graphics.update }
  file.puts ['replacement-advances',Audio.bgm_pos > before].join("\t")
  Audio.bgm_stop
end
File.open(File.join(output,'audio_zero_fade_reference.tsv'),'w') do |file|
  [:bgm,:bgs].each do |channel|
    Audio.send((channel.to_s+'_play').to_sym,tone,0,100)
    6.times { Graphics.update }
    Audio.send((channel.to_s+'_fade').to_sym,0)
    immediate=Audio.send((channel.to_s+'_pos').to_sym)
    12.times { Graphics.update }
    later=Audio.send((channel.to_s+'_pos').to_sym)
    file.puts [channel,'zero-fade-advances',later > immediate].join("\t")
    Audio.send((channel.to_s+'_stop').to_sym)
  end
end
exit unless $audio_replay_host
