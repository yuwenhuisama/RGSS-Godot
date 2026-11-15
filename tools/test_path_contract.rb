require_relative 'test_paths'
require_relative '../tests/fixtures/test_paths'
$test_repo_root = TestPathsConfig::ROOT
$test_game_project = TestPathsConfig.path('game_project')
$test_rtp_path = TestPathsConfig.path('rtp')
raise 'Fixture root mismatch' unless TestPaths.fixture('audio/tone.ogg') == File.join(TestPathsConfig::ROOT, 'tests/fixtures/audio/tone.ogg')
raise 'Configured map missing' unless File.exist?(TestPaths.game('Data/Map001.rvdata2'))
puts 'RUBY_TEST_PATH_CONFIG_PASS'
