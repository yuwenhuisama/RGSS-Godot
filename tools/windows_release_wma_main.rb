require 'audio'
failed = false
Audio.bgm_play(File.join(Unity.rmva_project_path, 'probes', 'latest-tone.wma'),
  40, 100, 0, proc { failed = true })
raise 'Windows combined package WMA load failed' if failed
Audio.bgm_stop
puts 'WINDOWS_COMBINED_WMA_PASS'
