require 'ext/onig_regexp'
require 'ext/dir_glob'
require 'ext/dir'
root = Unity.rmva_project_path
$native_extensions_host = true
$gzip_reference_host = true
$file_binary_host = true
$rgss_compat_output = File.join(root, 'results')
['native_extensions', 'gzip_reader_io', 'gzip_integrity', 'file_binary'].each do |name|
  eval(File.read(File.join(root, 'probes', name + '_reference.rb')))
  actual_name = name == 'native_extensions' ? name + '_reference.tsv' : name + '.tsv'
  actual = File.read(File.join($rgss_compat_output, actual_name)).gsub("\r\n", "\n").strip
  expected = File.read(File.join(root, 'probes', name + '_original.tsv')).gsub("\r\n", "\n").strip
  raise 'Mac release native mismatch: ' + name unless actual == expected
end
puts 'MACOS_RELEASE_ORIGINAL_NATIVE_PASS'
