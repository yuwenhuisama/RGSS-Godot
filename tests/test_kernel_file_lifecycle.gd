extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("user://kernel-file-lifecycle")
	DirAccess.make_dir_recursive_absolute(output.path_join("RMProject"))
	var code := "require 'kernel'; $rmva_project_base_path=" + JSON.stringify(output) + "\n"
	code += """
save_data([42], 'owned.rvdata2')
class << File
  alias_method :kernel_lifecycle_open, :open
  def open(*args, &block)
    if block
      return kernel_lifecycle_open(*args) do |file|
        $kernel_lifecycle_handle = file if args[0].include?('owned.rvdata2')
        block.call(file)
      end
    end
    file = kernel_lifecycle_open(*args)
    $kernel_lifecycle_handle = file if args[0].include?('owned.rvdata2')
    file
  end
end
value = load_data('owned.rvdata2')
raise 'load value changed' unless value == [42]
raise 'successful load left file open' unless $kernel_lifecycle_handle.closed?
File.open(File.join($rmva_project_base_path, 'RMProject', 'owned.rvdata2'), 'wb') { |file| file.write('broken') }
begin
  load_data('owned.rvdata2')
  raise 'invalid load accepted'
rescue TypeError
end
raise 'failed load left file open' unless $kernel_lifecycle_handle.closed?
File.delete(File.join($rmva_project_base_path, 'RMProject', 'owned.rvdata2'))
binary_path = File.join($rmva_project_base_path, 'RMProject', 'binary.dat')
File.open(binary_path, 'wb') { |file| file.write([0xc3, 0xa9, 0, 0xff].pack('C*')) }
File.open(binary_path, 'rb') do |file|
  bytes = file.read
  raise 'binary read encoding changed' unless bytes.encoding.name == 'ASCII-8BIT'
  raise 'binary read counts characters' unless bytes.size == 4 && bytes.bytesize == 4
  raise 'binary read changed bytes' unless bytes.unpack('H*')[0] == 'c3a900ff'
end
File.delete(binary_path)
"""
	var ok: bool = driver.RunRuby(code)
	ok = driver.RunRuby("$file_binary_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/file_binary_reference.rb")) and ok
	var actual := FileAccess.get_file_as_string(output.path_join("file_binary.tsv")).replace("\r\n", "\n").strip_edges()
	var expected := FileAccess.get_file_as_string("res://tests/fixtures/file_binary_original.tsv").replace("\r\n", "\n").strip_edges()
	if expected.is_empty() or actual != expected:
		push_error("File binary encoding differs from RGSS300: " + actual)
		ok = false
	driver.Shutdown()
	print("KERNEL_FILE_LIFECYCLE_PASS" if ok else "KERNEL_FILE_LIFECYCLE_FAIL")
	quit(0 if ok else 1)
