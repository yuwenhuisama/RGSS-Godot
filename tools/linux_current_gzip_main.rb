$gzip_reference_host = true
$rgss_compat_output = '/tmp'
eval(File.read(File.join(Unity.rmva_project_path, 'gzip_encoding_extended_reference.rb')))
actual = File.read('/tmp/gzip_encoding_extended.tsv').gsub("\r\n", "\n").strip
expected = File.read(File.join(Unity.rmva_project_path, 'gzip_encoding_extended_original.tsv')).gsub("\r\n", "\n").strip
raise 'Exported Gzip encoding mismatch' unless actual == expected
puts 'LINUX_CURRENT_EXPORTED_GZIP_PASS:14'
require 'audio'
failed = false
Audio.bgm_play('Audio/BGM/export-tone', 40, 100, 0, proc { failed = true })
raise 'Linux exported WMA load failed' if failed
Audio.bgm_stop
puts 'LINUX_EXPORTED_WMA_LOAD_PASS'
