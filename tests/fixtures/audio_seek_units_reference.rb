output = $rgss_compat_output || '.'
File.open(File.join(output,'audio_seek_units_reference.tsv'),'w') do |file|
  ['ogg','wav','wma','mid'].each do |format|
    path = format == 'mid' ? TestPaths.fixture('midi-reference.mid') : TestPaths.fixture('audio/tone.' + format)
    [4096,8192].each do |position|
      if format == 'mid'
        Audio.bgm_play(TestPaths.fixture('audio/tone.ogg'),0,100,4096)
        Graphics.update
      end
      Audio.bgm_stop
      Audio.bgm_play(path,0,100,position)
      immediate = Audio.bgm_pos
      4.times { Graphics.update }
      advanced = Audio.bgm_pos
      Audio.bgm_stop
      stopped = Audio.bgm_pos
      file.puts [format,position,immediate,advanced > immediate,stopped >= advanced,advanced,stopped].join("\t")
      file.flush
    end
  end
end
exit unless $audio_seek_units_host
