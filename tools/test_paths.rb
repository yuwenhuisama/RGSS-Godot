require 'json'
module TestPathsConfig
  ROOT = File.expand_path('..', __dir__)
  FILE = File.expand_path(ENV['RGSS_TEST_PATHS_FILE'] || File.join(ROOT, '.test-paths.local.json'))
  def self.repo(relative = '')
    File.join(ROOT, relative)
  end
  def self.setting(key)
    values = File.exist?(FILE) ? JSON.parse(File.read(FILE, encoding: 'bom|utf-8')) : {}
    value = values[key]
    raise "Missing test setting '#{key}' in #{FILE}. Copy .test-paths.example.json and configure this input." unless value.is_a?(String) && !value.strip.empty?
    value
  end
  def self.path(key)
    File.expand_path(setting(key), File.dirname(FILE))
  end
  def self.fixture_source(source)
    values = File.exist?(FILE) ? JSON.parse(File.read(FILE, encoding: 'bom|utf-8')) : {}
    setup = "$test_repo_root=#{ROOT.inspect}\n"
    {'game_project' => '$test_game_project', 'rtp' => '$test_rtp_path'}.each do |key, global|
      setup += "#{global}=#{path(key).inspect}\n" if values[key].is_a?(String) && !values[key].empty?
    end
    setup + File.read(repo('tests/fixtures/test_paths.rb')) + "\n" + source
  end
end
if $PROGRAM_NAME == __FILE__
  begin
    operation, argument = ARGV
    raise 'Usage: test_paths.rb repo [relative] | path key | setting key' unless ['repo', 'path', 'setting'].include?(operation)
    puts operation == 'repo' ? TestPathsConfig.repo(argument || '') : TestPathsConfig.public_send(operation, argument)
  rescue StandardError => error
    warn error.message
    exit 1
  end
end
