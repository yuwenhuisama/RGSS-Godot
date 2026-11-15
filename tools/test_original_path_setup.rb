require_relative 'test_paths'
require 'zlib'
require 'tmpdir'
require 'fileutils'

Dir.mktmpdir('rgss-test-path-setup') do |work|
  fixture = File.join(work, 'probe.rb')
  File.write(fixture, "raise 'repo fixture missing' unless File.exist?(TestPaths.fixture('audio/tone.ogg'))\nputs 'ORIGINAL_PATH_PRELUDE_PASS'\n")
  output = File.join(work, 'isolated project')
  command = [RbConfig.ruby, TestPathsConfig.repo('tools/prepare_original_fixture.rb'), TestPathsConfig.path('game_project'), output, fixture]
  raise 'Isolated original fixture preparation failed' unless system(*command)
  payload = Marshal.load(File.binread(File.join(output, 'Data/Scripts.rvdata2')))
  source = Zlib::Inflate.inflate(payload.last[2])
  eval(source, TOPLEVEL_BINDING, fixture)
  raise 'Local config must not be copied to original project' if File.exist?(File.join(output, '.test-paths.local.json'))
end
