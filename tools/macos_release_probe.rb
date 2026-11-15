require 'ext/onig_regexp'
require 'ext/dir_glob'
require 'ext/dir'
require 'audio'
raise 'defined mismatch' unless defined?(Object) == 'constant'
payload = [2 ** 100, 'macos-export', {:value => 42}]
raise 'marshal mismatch' unless Marshal.load(Marshal.dump(payload)) == payload
raise 'zlib mismatch' unless Zlib::Inflate.inflate(Zlib::Deflate.deflate('macos-native')) == 'macos-native'
raise 'regexp mismatch' unless /(?<=ab)cd/.match('abcd')[0] == 'cd'
failed = false
Audio.bgm_play(File.join(Unity.rmva_project_path, 'tone.wma'), 40, 100, 0, proc { failed = true })
raise 'WMA load failed' if failed
Audio.bgm_stop
puts 'MACOS_RELEASE_NATIVE_WMA_PASS'
