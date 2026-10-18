extends SceneTree

const SHEETS := {
	"idle": "res://assets/sprites/player_idle.png",
	"walk": "res://assets/sprites/player_walk.png",
	"attack": "res://assets/sprites/player_attack.png",
	"death": "res://assets/sprites/player_death.png",
}
const ALLOWED_COLORS := {
	"080b18": true, "10152b": true, "1b2340": true, "293354": true,
	"37314f": true, "59476f": true, "075a80": true, "087fb2": true,
	"0eb8d4": true, "37e8f5": true, "7623a8": true, "826999": true,
	"ad91bb": true, "e13acb": true, "ffd447": true, "fff19a": true,
}

func _initialize() -> void:
	for animation in SHEETS:
		if not _check_sheet(animation, SHEETS[animation]):
			quit(1)
			return
	print("Original player animation sheets and editable sources passed")
	quit()

func _check_sheet(animation: String, png_path: String) -> bool:
	var texture := load(png_path) as Texture2D
	var source_directory := "animation" if animation in ["attack", "death"] else "pilot"
	var source_path := "res://assets/source/%s/player_%s.aseprite" % [source_directory, animation]
	if texture == null or texture.get_size() != Vector2(128, 128) or not FileAccess.file_exists(source_path):
		push_error("Player %s needs a 4x4 32x32 sheet and editable Aseprite source" % animation)
		return false
	var image := texture.get_image()
	for row in range(4):
		for column in range(4):
			var colors := {}
			for y in range(row * 32, (row + 1) * 32):
				for x in range(column * 32, (column + 1) * 32):
					var pixel := image.get_pixel(x, y)
					if pixel.a == 0.0:
						continue
					var color := pixel.to_html(false)
					if not ALLOWED_COLORS.has(color):
						push_error("Player %s uses a color outside the Art Bible subset: %s" % [animation, color])
						return false
					colors[color] = true
			if colors.is_empty() or colors.size() > 16:
				push_error("Every player %s frame must be visible and use at most 16 colors" % animation)
				return false
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or \
		source.get_16() != 1 or source.get_16() != 128 or source.get_16() != 128:
		push_error("Player %s Aseprite source does not match the sheet" % animation)
		return false
	return true
