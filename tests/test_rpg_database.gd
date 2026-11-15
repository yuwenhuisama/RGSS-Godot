extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/rpg-database")
	DirAccess.make_dir_recursive_absolute(output)
	var code := "require 'color'; require 'tone'; require 'table'; require 'ext/dir'; require 'ext/onig_regexp'; require 'ext/dir_glob'; module RPG; end\n"
	var files := DirAccess.get_files_at("res://RGSS/rpg")
	files.sort()
	for file in files:
		if file.ends_with(".rb"):
			code += "require " + JSON.stringify("rpg/" + file.trim_suffix(".rb")) + "\n"
	code += "$rpg_database_host=true; $rpg_database_source=File.join(Unity.rmva_project_path, 'RMProject/Data'); $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/rpg_database_reference.rb")
	var ok: bool = driver.RunRuby(code)
	var expected_rows := FileAccess.get_file_as_string("res://tests/fixtures/rpg_database_original_hashes.tsv").strip_edges().split("\n")
	var compared := 0
	for row in expected_rows:
		var fields := row.split("\t")
		if fields.size() != 3:
			ok = false
			continue
		compared += 1
		var bytes := FileAccess.get_file_as_bytes(output.path_join(fields[0]))
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(bytes)
		if bytes.size() != int(fields[1]) or hash.finish().hex_encode() != fields[2]:
			push_error("Loaded database fields differ: " + fields[0])
			ok = false
	if compared != 15:
		push_error("Original database ledger must cover15 files")
		ok = false
	print("RPG_DATABASE_COMPARED:%d" % compared)
	driver.Shutdown()
	print("RPG_DATABASE_PASS" if ok else "RPG_DATABASE_FAIL")
	quit(0 if ok else 1)
