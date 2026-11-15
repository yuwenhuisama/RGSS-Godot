extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var driver = load("res://Scripts/StressDisposeTestDriver.cs").new()
	var host := Node.new()
	root.add_child(host)
	driver.Initialize(host)
	var output := ProjectSettings.globalize_path("res://.omo/evidence/rmva-compatibility/godot/marshal-links")
	DirAccess.make_dir_recursive_absolute(output)
	var peer_hex := FileAccess.get_file_as_string("res://tests/fixtures/marshal_links_original.hex").strip_edges()
	var code := "$marshal_links_host=true; $marshal_links_peer_bytes=[" + JSON.stringify(peer_hex) + "].pack('H*'); $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/marshal_links_reference.rb")
	var ok: bool = driver.RunRuby(code)
	ok = driver.RunRuby("$marshal_identity_host=true; $rgss_compat_output=" + JSON.stringify(output) + "\n" + FileAccess.get_file_as_string("res://tests/fixtures/marshal_identity_reference.rb")) and ok
	var text := FileAccess.get_file_as_string(output.path_join("marshal_links_reference.tsv")).replace("\r\n", "\n").strip_edges()
	print(text)
	ok = text.sha256_text() == "03218f85c239ab7af9296e4b58f8b4a18470095571422cb45f7aa43f0c8f032b" and ok
	var peer_text := FileAccess.get_file_as_string(output.path_join("marshal_peer_reference.tsv")).replace("\r\n", "\n").strip_edges()
	ok = peer_text == "\n".join(text.split("\n").slice(0, 5)) and ok
	driver.Shutdown()
	print("MARSHAL_LINKS_PASS" if ok else "MARSHAL_LINKS_FAIL")
	quit(0 if ok else 1)
