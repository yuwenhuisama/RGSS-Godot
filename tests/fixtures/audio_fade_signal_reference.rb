output = $rgss_compat_output || '.'
tone = $audio_fade_tone || 'long-tone.wav'
Graphics.frame_rate = 60
File.open(File.join(output, 'audio_fade_events.tsv'), 'w') do |file|
  ['bgm', 'bgs'].each do |channel|
    Audio.send(channel + '_play', tone, $audio_fade_volume || 20, 100)
    file.puts [channel, 'play', Time.now.to_f].join("\t")
    file.flush
    60.times { Graphics.update }
    Audio.send(channel + '_fade', $audio_fade_duration || 2000)
    file.puts [channel, 'fade', Time.now.to_f].join("\t")
    file.flush
    180.times { Graphics.update }
    Audio.send(channel + '_stop')
    file.puts [channel, 'stop', Time.now.to_f].join("\t")
    file.flush
    30.times { Graphics.update }
  end
end
exit unless $audio_fade_host
