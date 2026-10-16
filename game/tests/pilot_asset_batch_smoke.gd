extends SceneTree

const ASSETS := {
	"player_cyan": Vector2i(32, 32),
	"enemy_chaser": Vector2i(24, 24),
	"projectile_lightning": Vector2i(16, 16),
}

func _initialize() -> void:
	for asset_name in ASSETS:
		var png_path := "res://assets/sprites/%s.png" % asset_name
		var ase_path := "res://assets/source/pilot/%s.aseprite" % asset_name
		if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
			_fail("Missing PNG or editable Aseprite source for %s" % asset_name)
			return
		var image := (load(png_path) as Texture2D).get_image()
		if image.get_size() != ASSETS[asset_name]:
			_fail("Unexpected dimensions for %s: %s" % [asset_name, image.get_size()])
			return
		var colors := {}
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel := image.get_pixel(x, y)
				if pixel.a > 0.0:
					colors[pixel.to_html(false)] = true
		if colors.size() > 16:
			_fail("Asset %s exceeds the 16-color cap: %d" % [asset_name, colors.size()])
			return
		var source := FileAccess.open(ase_path, FileAccess.READ)
		if source.get_32() != source.get_length() or source.get_16() != 0xA5E0:
			_fail("Invalid Aseprite file header for %s" % asset_name)
			return
		if source.get_16() != 1 or source.get_16() != image.get_width() or source.get_16() != image.get_height():
			_fail("Aseprite dimensions differ from PNG for %s" % asset_name)
			return
		source.seek(128)
		if source.get_32() != source.get_length() - 128 or source.get_16() != 0xF1FA or source.get_16() != 2:
			_fail("Invalid Aseprite frame header for %s" % asset_name)
			return
		source.seek(144)
		for expected_chunk in [0x2004, 0x2005]:
			var chunk_size := source.get_32()
			if source.get_16() != expected_chunk or chunk_size < 6:
				_fail("Invalid Aseprite layer/cel chunk for %s" % asset_name)
				return
			source.seek(source.get_position() + chunk_size - 6)
		if source.get_position() != source.get_length():
			_fail("Aseprite chunks do not fill the file for %s" % asset_name)
			return
	print("Pilot asset batch smoke passed")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
