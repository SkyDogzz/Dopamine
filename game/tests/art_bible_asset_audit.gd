extends SceneTree

const ASSET_ROOT := "res://assets"
const PALETTE_PATH := "res://../docs/art/palette_master.gpl"
const COLOR_LIMIT := 16

var _palette := {}
var _png_paths: Array[String] = []
var _errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_load_palette()
	_collect_pngs(ASSET_ROOT)
	for path in _png_paths:
		_validate_image(path)
	if _errors.is_empty():
		print("Art Bible asset audit passed: %d runtime PNGs use the 32-color palette; 32x32 sprites stay within %d colors" % [_png_paths.size(), COLOR_LIMIT])
		quit()
		return
	for error in _errors:
		push_error(error)
	quit(1)

func _load_palette() -> void:
	var file := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		_errors.append("Missing Art Bible palette: %s" % PALETTE_PATH)
		return
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("GIMP Palette") or \
			line.begins_with("Name:") or line.begins_with("Columns:"):
			continue
		var columns := line.split(" ", false)
		if columns.size() < 3 or not columns[0].is_valid_int() or not columns[1].is_valid_int() or not columns[2].is_valid_int():
			continue
		_palette[_rgb_key(int(columns[0]), int(columns[1]), int(columns[2]))] = true
	if _palette.size() != 32:
		_errors.append("Art Bible palette must contain exactly 32 RGB colors (found %d)" % _palette.size())

func _collect_pngs(directory: String) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		_errors.append("Cannot inspect asset directory: %s" % directory)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var path := directory.path_join(entry)
			if dir.current_is_dir():
				_collect_pngs(path)
			elif entry.get_extension().to_lower() == "png" and not directory.contains("/source/"):
				_png_paths.append(path)
		entry = dir.get_next()
	dir.list_dir_end()

func _validate_image(path: String) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		_errors.append("Cannot load PNG: %s" % path)
		return
	var colors := _used_palette_colors(image, Rect2i(Vector2i.ZERO, image.get_size()), path)
	if image.get_size() == Vector2i(32, 32) and colors.size() > COLOR_LIMIT:
		_errors.append("32x32 sprite exceeds the 16-color Art Bible limit (%d): %s" % [colors.size(), path])
	if path.get_file() in ["player_idle.png", "player_walk.png"]:
		_validate_player_sheet(image, path)
	if path.ends_with("/sprites/weapon_impacts_pixel.png"):
		if image.get_size() != Vector2i(640, 64):
			_errors.append("Impact atlas must contain ten 64x64 cells: %s" % path)
			return
		for cell in range(10):
			_used_palette_colors(image, Rect2i(cell * 64, 0, 64, 64), "%s cell %d" % [path, cell])

func _validate_player_sheet(image: Image, path: String) -> void:
	if image.get_size() != Vector2i(128, 128):
		_errors.append("Player animation sheet must be 128x128 (4x4 frames of 32x32): %s" % path)
		return
	for row in range(4):
		for column in range(4):
			var bounds := Rect2i(column * 32, row * 32, 32, 32)
			var colors := _used_palette_colors(image, bounds, "%s row=%d column=%d" % [path, row, column])
			if colors.size() > COLOR_LIMIT:
				_errors.append("Player frame row=%d column=%d exceeds 16 colors (%d): %s" % [row, column, colors.size(), path])

func _used_palette_colors(image: Image, bounds: Rect2i, asset_label: String) -> Dictionary:
	var colors := {}
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			var key := _rgb_key(roundi(color.r * 255.0), roundi(color.g * 255.0), roundi(color.b * 255.0))
			colors[key] = true
			if not _palette.has(key):
				var error := "Image color #%s is outside the Art Bible palette: %s" % [key, asset_label]
				if not _errors.has(error):
					_errors.append(error)
	return colors

func _rgb_key(red: int, green: int, blue: int) -> String:
	return "%02x%02x%02x" % [red, green, blue]
