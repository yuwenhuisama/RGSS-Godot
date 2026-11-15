extends SceneTree

const TestPaths = preload("res://tools/test_paths.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var bootstrap_ok: bool = driver.RunRuby("require 'ext/onig_regexp'; require 'ext/dir_glob'; require 'ext/dir'")
	var output := TestPaths.output("native-extensions")
	DirAccess.make_dir_recursive_absolute(output)
	var path := output.path_join("native_extensions_reference.tsv")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var code := "$native_extensions_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("native_extensions_reference.rb"))
	var ok: bool = driver.RunRuby(code) and bootstrap_ok
	var checksum_code := "$zlib_checksum_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("zlib_checksum_reference.rb"))
	ok = driver.RunRuby(checksum_code) and ok
	var gzip_code := "$gzip_reference_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("gzip_reference.rb"))
	ok = driver.RunRuby(gzip_code) and ok
	ok = driver.RunRuby("$gzip_reference_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("gzip_encoding_reference.rb"))) and ok
	var encoding_actual := FileAccess.get_file_as_string(output.path_join("gzip_encoding_reference.tsv")).replace("\r\n", "\n").strip_edges()

	ok = driver.RunRuby("$gzip_reference_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("gzip_encoding_extended_reference.rb"))) and ok
	var extended_actual := FileAccess.get_file_as_string(output.path_join("gzip_encoding_extended.tsv")).replace("\r\n", "\n").strip_edges()
	var extended_expected := FileAccess.get_file_as_string(TestPaths.fixture("gzip_encoding_extended_original.tsv")).replace("\r\n", "\n").strip_edges()
	if extended_expected.is_empty() or extended_actual != extended_expected:
		push_error("Extended Gzip encoding options differ from original RGSS300: " + extended_actual)
		ok = false
	var encoding_expected := FileAccess.get_file_as_string(TestPaths.fixture("gzip_encoding_original.tsv")).replace("\r\n", "\n").strip_edges()
	ok = driver.RunRuby("$gzip_reference_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("gzip_reader_io_reference.rb"))) and ok
	var io_actual := FileAccess.get_file_as_string(output.path_join("gzip_reader_io.tsv")).replace("\r\n", "\n").strip_edges()
	var io_expected := FileAccess.get_file_as_string(TestPaths.fixture("gzip_reader_io_original.tsv")).replace("\r\n", "\n").strip_edges()
	if io_expected.is_empty() or io_actual != io_expected:
		push_error("Gzip reader IO differs from original RGSS300: " + io_actual)
		ok = false
	ok = driver.RunRuby("$gzip_reference_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + TestPaths.ruby_setup() + FileAccess.get_file_as_string(TestPaths.fixture("gzip_integrity_reference.rb"))) and ok
	var integrity_actual := FileAccess.get_file_as_string(output.path_join("gzip_integrity.tsv")).replace("\r\n", "\n").strip_edges()
	var integrity_expected := FileAccess.get_file_as_string(TestPaths.fixture("gzip_integrity_original.tsv")).replace("\r\n", "\n").strip_edges()
	if integrity_expected.is_empty() or integrity_actual != integrity_expected:
		push_error("Gzip integrity behavior differs from original RGSS300: " + integrity_actual)
		ok = false
	if encoding_expected.is_empty() or encoding_actual != encoding_expected:
		push_error("Gzip encoding options differ from original RGSS300: " + encoding_actual)
		ok = false
	ok = driver.RunRuby("begin; Zlib::GzipFile.allocate; raise 'GzipFile.allocate accepted an abstract stream'; rescue TypeError => error; raise 'GzipFile.allocate wrong error' unless error.message == 'allocator undefined for Zlib::GzipFile'; end; raise 'GzipReader allocation failed' unless Zlib::GzipReader.allocate.is_a?(Zlib::GzipReader); raise 'GzipWriter allocation failed' unless Zlib::GzipWriter.allocate.is_a?(Zlib::GzipWriter)") and ok
	var gzip_actual := FileAccess.get_file_as_string(output.path_join("gzip_reference.tsv")).replace("\r\n", "\n").strip_edges()
	var gzip_expected := FileAccess.get_file_as_string(TestPaths.fixture("gzip_original.tsv")).replace("\r\n", "\n").strip_edges()
	if gzip_expected.is_empty() or gzip_actual != gzip_expected:
		push_error("Gzip behavior differs from the eight original RGSS300 rows: " + gzip_actual)
		ok = false
	var checksums := FileAccess.get_file_as_string(output.path_join("zlib_checksum_reference.tsv")).replace("\r\n", "\n")
	# Table/version match RGSS300; combine values come from standalone Ruby
	# because this installed original hangs for both positive and zero length.
	var expected_checksums := "crc-combine\t1029712306\nadler-combine\t300286872\ncrc-combine-empty\t2615402659\nadler-combine-empty\t64618901\ncrc-table\t256,0,1996959894,755167117\nversion-format\ttrue"
	if checksums.strip_edges() != expected_checksums:
		push_error("Zlib checksum behavior differs from measured references: " + checksums)
		ok = false
	if "\terror\t" in checksums:
		push_error("Zlib checksum module methods missing or failed: " + checksums)
		ok = false
	var actual := FileAccess.get_file_as_string(path).replace("\r\n","\n").strip_edges()
	var expected := FileAccess.get_file_as_string(TestPaths.fixture("native_extensions_original.tsv")).replace("\r\n","\n").strip_edges()
	if DirAccess.dir_exists_absolute(output.path_join("junction-probe")):
		expected += "\nsymlink-junction\tfalse\nglob-junction\tjunction-probe/c.txt"
	print(actual)
	ok = not expected.is_empty() and actual == expected and ok
	driver.Shutdown()
	print("NATIVE_EXTENSIONS_PASS" if ok else "NATIVE_EXTENSIONS_FAIL")
	quit(0 if ok else 1)
