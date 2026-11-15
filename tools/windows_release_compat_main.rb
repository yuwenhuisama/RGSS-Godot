require 'ext/onig_regexp'
require 'ext/dir_glob'
require 'ext/dir'
require 'audio'
require 'graphics'
$native_extensions_host = true
$gzip_reference_host = true
$file_binary_host = true
root = Unity.rmva_project_path
$rgss_compat_output = File.join(root, 'results')
['native_extensions', 'gzip_reader_io', 'gzip_integrity', 'file_binary'].each do |name|
  eval(File.read(File.join(root, 'probes', name + '_reference.rb')))
  actual_name = name == 'native_extensions' ? name + '_reference.tsv' : name + '.tsv'
  actual = File.read(File.join($rgss_compat_output, actual_name)).gsub("\r\n", "\n").strip
  expected = File.read(File.join(root, 'probes', name + '_original.tsv')).gsub("\r\n", "\n").strip
  raise 'Windows release native mismatch: ' + name unless actual == expected
end
puts 'WINDOWS_RELEASE_NATIVE_FILE_PASS'
Unity.register_update_fiber(Fiber.new do
  Audio.setup_midi
  ['midi-reference.mid', 'midi-reference-sysex.mid', 'midi-reference-smpte.mid'].each do |name|
    Audio.bgm_play(File.join(root, 'probes', name), 80, 100, 8192)
    30.times { Graphics.update }
    raise 'Windows release MIDI position mismatch' unless Audio.bgm_pos == 0
    Audio.bgm_stop
  end
  puts 'WINDOWS_RELEASE_MIDI_PASS'
  loop { Graphics.update }
end)
