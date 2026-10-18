extends SceneTree

const PNG_PATH := "res://assets/icons/ui/signal_prism.png"
const ASE_PATH := "res://assets/source/original_procedural/signal_prism.aseprite"
const PALETTE := [
	"080b18", "10152b", "1b2340", "075a80", "087fb2", "0eb8d4", "37e8f5",
	"7623a8", "a52dca", "e13acb", "ff75e3", "a85b19", "e69825", "ffd447",
	"fff19a", "f6f7ff",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(PNG_PATH))
	if image == null or image.get_size() != Vector2i(32, 32):
		_fail("Signal Prism should export as a 32x32 sprite")
		return
	if image.get_pixel(0, 0).a != 0.0:
		_fail("Signal Prism should preserve a transparent background")
		return
	var colors: Dictionary = {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.5:
				continue
			var color := pixel.to_html(false)
			colors[color] = true
			if color not in PALETTE:
				_fail("Signal Prism uses a color outside the Art Bible palette: %s" % color)
				return
	if colors.size() > 16:
		_fail("A 32x32 sprite should use at most 16 distinct colors")
		return
	if not FileAccess.file_exists(ProjectSettings.globalize_path(ASE_PATH)):
		_fail("Signal Prism should include its editable Aseprite source")
		return
	var editable := FileAccess.open(ASE_PATH, FileAccess.READ)
	if editable == null:
		_fail("Signal Prism editable source should have a valid Aseprite header")
		return
	editable.seek(4)
	if editable.get_16() != 0xA5E0:
		_fail("Signal Prism editable source should have a valid Aseprite header")
		return
	if editable.get_16() != 1 or editable.get_16() != 32 or editable.get_16() != 32 or editable.get_16() != 32:
		_fail("Aseprite source should be one 32x32 RGBA frame")
		return
	var launch: Control = load("res://scenes/launch_menu.tscn").instantiate()
	var logo := launch.get_node("Content/Columns/Identity/TitleRow/Logo") as TextureRect
	logo.texture = load(PNG_PATH) as Texture2D
	if logo.texture == null or logo.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("The title menu should use the Signal Prism with nearest-neighbor filtering")
		return
	launch.free()
	print("Signal Prism palette, dimensions, source and title integration passed (%d colors)" % colors.size())
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
	quit(1)
