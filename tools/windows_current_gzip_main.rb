$gzip_reference_host = true
$rgss_compat_output = Unity.rmva_project_path
eval(File.read(File.join(Unity.rmva_project_path, 'gzip_encoding_extended_reference.rb')))
actual = File.read(File.join(Unity.rmva_project_path, 'gzip_encoding_extended.tsv')).gsub("\r\n", "\n").strip
expected = File.read(File.join(Unity.rmva_project_path, 'gzip_encoding_extended_original.tsv')).gsub("\r\n", "\n").strip
raise 'Exported Gzip encoding mismatch' unless actual == expected
puts 'WINDOWS_CURRENT_EXPORTED_GZIP_PASS:14'
