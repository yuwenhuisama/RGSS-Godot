require 'audio'
$linux_export_audio_failed = false
Audio.bgm_play('Audio/BGM/export-tone', 40, 100, 0, proc { $linux_export_audio_failed = true })
raise 'Linux exported WMA load failed' if $linux_export_audio_failed
Audio.bgm_stop
puts 'LINUX_EXPORTED_WMA_LOAD_PASS'
