require 'ext/onig_regexp'
require 'ext/dir_glob'
require 'ext/dir'
raise 'release defined mismatch' unless defined?(Object) == 'constant'
payload = [2 ** 100, 'release-native', {:value => 42}]
raise 'release marshal mismatch' unless Marshal.load(Marshal.dump(payload)) == payload
$native_extensions_host = true
$gzip_reference_host = true
$file_binary_host = true
$rgss_compat_output = '/evidence'
['native_extensions', 'gzip_reader_io', 'gzip_integrity', 'file_binary'].each do |name|
  eval(File.read(File.join(Unity.rmva_project_path, 'probes', name + '_reference.rb')))
  actual_name = name == 'native_extensions' ? name + '_reference.tsv' : name + '.tsv'
  actual = File.read(File.join($rgss_compat_output, actual_name)).gsub("\r\n", "\n").strip
  expected = File.read(File.join(Unity.rmva_project_path, 'probes', name + '_original.tsv')).gsub("\r\n", "\n").strip
  raise 'release native mismatch: ' + name unless actual == expected
end
puts 'LINUX_RELEASE_CLEAN_NATIVE_PASS'
