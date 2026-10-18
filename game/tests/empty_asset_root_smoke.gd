extends SceneTree

const ASSET_ROOT := "res://assets"
const CREATIVE_EXTENSIONS := ["png", "ase", "aseprite", "wav", "ogg", "mp3", "flac", "ttf", "otf", "import"]

func _initialize() -> void:
	var creative_files: Array[String] = []
	_scan("", creative_files)
	if not creative_files.is_empty():
		push_error("Expected empty creative asset root, found: %s" % ", ".join(creative_files))
		quit(1)
		return
	print("Asset root is empty of visual/audio exports, sources and import sidecars")
	quit(0)

func _scan(relative_path: String, result: Array[String]) -> void:
	var absolute_path := ProjectSettings.globalize_path(ASSET_ROOT.path_join(relative_path))
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child := relative_path.path_join(entry)
			if directory.current_is_dir():
				_scan(child, result)
			elif CREATIVE_EXTENSIONS.has(entry.get_extension().to_lower()):
				result.append(child)
		entry = directory.get_next()
	directory.list_dir_end()
