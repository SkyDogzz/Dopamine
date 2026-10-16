extends SceneTree

const SOURCE_PATH := "res://../docs/art/source/title_skyline_generated.png"
const OUTPUT_PATH := "res://assets/backgrounds/title_skyline.png"
const OUTPUT_SIZE := Vector2i(640, 360)
const PALETTE := [
	"080B18", "10152B", "1B2340", "293354", "3D4868", "586381", "7B87A2", "A5AEC3",
	"D4D9E8", "F6F7FF", "37314F", "59476F", "826999", "AD91BB", "D2B9D9", "EEDCF4",
	"075A80", "087FB2", "0EB8D4", "37E8F5", "7623A8", "A52DCA", "E13ACB", "FF75E3",
	"A85B19", "E69825", "FFD447", "FFF19A", "158C62", "48E69B", "C83B62", "FF7181",
]

func _initialize() -> void:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(SOURCE_PATH)) != OK:
		push_error("Could not load generated skyline source")
		quit(1)
		return
	image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var palette_colors: Array[Color] = []
	for hex_color in PALETTE:
		palette_colors.append(Color.html(hex_color))
	var colors_used: Dictionary = {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source_color := image.get_pixel(x, y)
			var nearest_color: Color = palette_colors[0]
			var nearest_distance := INF
			for palette_color in palette_colors:
				var red_delta := source_color.r - palette_color.r
				var green_delta := source_color.g - palette_color.g
				var blue_delta := source_color.b - palette_color.b
				var distance := red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_color = palette_color
			image.set_pixel(x, y, nearest_color)
			colors_used[nearest_color.to_html(false)] = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))
	if image.save_png(OUTPUT_PATH) != OK:
		push_error("Could not save pixelized skyline")
		quit(1)
		return
	print("Saved %s (%dx%d, %d Art Bible palette colors)" % [OUTPUT_PATH, OUTPUT_SIZE.x, OUTPUT_SIZE.y, colors_used.size()])
	quit()
