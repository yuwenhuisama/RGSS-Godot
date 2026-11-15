# Shared fixture path resolution for Godot and original RGSS300 probes.
# Host runners prepend this file through TestPaths.ruby_setup(); original
# fixture preparation prepends the same globals before evaluating a fixture.
module TestPaths
  class << self

  def repo(relative = '')
    rooted(required_setting($test_repo_root, '$test_repo_root'), relative)
  end

  def fixture(relative = '')
    repo(File.join('tests', 'fixtures', relative))
  end

  def game(relative = '')
    rooted(required_setting($test_game_project, '$test_game_project'), relative)
  end

  def rtp(relative = '')
    rooted(required_setting($test_rtp_path, '$test_rtp_path'), relative)
  end

  def output(relative = '')
    base = required_setting($rgss_compat_output, '$rgss_compat_output')
    make_directory(base)
    path = rooted(base, relative)
    make_directory(File.dirname(path))
    path
  end

  def required_setting(value, name)
    if value.nil? || value.to_s.strip.empty?
      raise "#{name} is not configured; use tools/test_paths.gd or RGSS_TEST_PATHS_FILE"
    end
    value.to_s
  end

  def rooted(base, relative)
    root = base.to_s.tr('\\', '/')
    root = root[0...-1] while root.end_with?('/')
    return root if relative.nil? || relative.to_s.empty?
    suffix = relative.to_s.tr('\\', '/')
    suffix = suffix[1..-1] while suffix.start_with?('/')
    root + '/' + suffix
  end

  def make_directory(path)
    return if path.nil? || path.empty? || File.directory?(path)
    parent = File.dirname(path)
    make_directory(parent) unless parent == path
    Dir.mkdir(path)
  end
  end
end
