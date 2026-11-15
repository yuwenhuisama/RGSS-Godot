output = $rgss_compat_output || '.'
tone = $se_capacity_tone || 'long-tone.wav'
Graphics.frame_rate = 60
File.open(File.join(output, 'se_capacity_events.tsv'), 'w') do |file|
  [8, 9, 16, 17].each do |count|
    Audio.se_stop
    30.times { Graphics.update }
    count.times { |index| Audio.se_play(tone, 10, 50 + index * 5) }
    file.puts [count, 'start', Time.now.to_f].join("\t")
    file.flush
    90.times { Graphics.update }
    Audio.se_stop
    file.puts [count, 'stop', Time.now.to_f].join("\t")
    file.flush
  end
  30.times { Graphics.update }
end
exit unless $se_capacity_host
