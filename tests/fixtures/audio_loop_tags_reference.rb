output=$rgss_compat_output || '.'
tone=TestPaths.fixture('audio/loop-tagged.ogg')
Graphics.frame_rate=60
File.open(File.join(output,'audio_loop_tags_reference.tsv'),'w') do |file|
  [:bgm,:bgs].each do |channel|
    Audio.send((channel.to_s+'_play').to_sym,tone,0,100)
    150.times { Graphics.update }
    position=Audio.send((channel.to_s+'_pos').to_sym)
    file.puts [channel,position].join("\t")
    file.flush
    Audio.send((channel.to_s+'_stop').to_sym)
  end
end
exit unless $audio_loop_tags_host
