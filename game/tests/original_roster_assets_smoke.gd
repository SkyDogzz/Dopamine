extends SceneTree

const ROLES := ["buffer", "chaser", "exploder", "shielder", "shooter", "sprinter", "summoned", "summoner", "tank"]

func _initialize() -> void:
	var allowed := _load_palette()
	if allowed.is_empty():
		quit(1)
		return
	for role in ROLES:
		if not _check_role(role, allowed):
			quit(1)
			return
	var generator := FileAccess.get_file_as_string("res://tools/generate_original_roster.py")
	if generator.contains("generated_reference") or generator.contains("build_catalog_icon_assets"):
		push_error("Original roster generator must not read legacy reference sheets or recipes")
		quit(1)
		return
	var legacy_builder := FileAccess.get_file_as_string("res://tools/build_catalog_icon_assets.gd")
	if not legacy_builder.contains("for index in range(9, ROSTER_NAMES.size())"):
		push_error("Legacy roster builder must not overwrite the migrated common enemy sprites")
		quit(1)
		return
	print("Original common roster PNGs, editable sources and migration boundary passed")
	quit()

func _load_palette() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://../docs/art/palette_master.gpl")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot read master palette")
		return {}
	var colors := {}
	for line in file.get_as_text().split("\n"):
		var fields := line.strip_edges().split(" ", false)
		if fields.size() >= 3 and fields[0].is_valid_int() and fields[1].is_valid_int() and fields[2].is_valid_int():
			var color := Color8(int(fields[0]), int(fields[1]), int(fields[2])).to_html(false)
			colors[color] = true
	return colors

func _check_role(role: String, allowed: Dictionary) -> bool:
	var png := "res://assets/sprites/roster/enemy_%s.png" % role
	var source_path := "res://assets/source/roster/enemy_%s.aseprite" % role
	var texture := load(png) as Texture2D
	if texture == null or texture.get_size() != Vector2(24, 24):
		push_error("Enemy %s must export as a 24x24 sprite" % role)
		return false
	var image := texture.get_image()
	var colors := {}
	var visible := false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			visible = true
			var html := pixel.to_html(false)
			if not allowed.has(html):
				push_error("Enemy %s uses a color outside the master palette: %s" % [role, html])
				return false
			colors[html] = true
	if not visible or colors.size() > 16:
		push_error("Enemy %s needs a visible silhouette using no more than 16 colors" % role)
		return false
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or \
			source.get_16() != 1 or source.get_16() != 24 or source.get_16() != 24:
		push_error("Enemy %s needs a matching editable 24x24 Aseprite source" % role)
		return false
	return true
