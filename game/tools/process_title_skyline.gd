extends SceneTree

const SOURCE_PATH := "res://../docs/art/source/title_skyline_generated.png"
const OUTPUT_PATH := "res://assets/backgrounds/title_skyline.png"
const SOURCE_ASE_PATH := "res://assets/source/backgrounds/title_skyline.aseprite"
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/source/backgrounds"))
	if image.save_png(OUTPUT_PATH) != OK or not _save_aseprite(image, SOURCE_ASE_PATH, "title_skyline"):
		push_error("Could not save pixelized skyline")
		quit(1)
		return
	print("Saved %s (%dx%d, %d Art Bible palette colors)" % [OUTPUT_PATH, OUTPUT_SIZE.x, OUTPUT_SIZE.y, colors_used.size()])
	quit()

func _save_aseprite(image: Image, path: String, layer_name: String) -> bool:
	var layer := PackedByteArray()
	for value in [3, 0, 0, 0, 0, 0]: _u16(layer, value)
	layer.append(255)
	layer.append_array([0, 0, 0])
	_string(layer, layer_name)
	var cel := PackedByteArray()
	for value in [0, 0, 0]: _u16(cel, value)
	cel.append(255)
	_u16(cel, 0)
	_u16(cel, 0)
	cel.append_array([0, 0, 0, 0, 0])
	_u16(cel, image.get_width())
	_u16(cel, image.get_height())
	cel.append_array(image.get_data())
	var chunks := _chunk(0x2004, layer) + _chunk(0x2005, cel)
	var frame := PackedByteArray()
	_u32(frame, chunks.size() + 16)
	_u16(frame, 0xF1FA)
	_u16(frame, 2)
	_u16(frame, 100)
	frame.append_array([0, 0])
	_u32(frame, 0)
	frame.append_array(chunks)
	var file := PackedByteArray()
	file.resize(128)
	file.encode_u32(0, 128 + frame.size())
	file.encode_u16(4, 0xA5E0)
	file.encode_u16(6, 1)
	file.encode_u16(8, image.get_width())
	file.encode_u16(10, image.get_height())
	file.encode_u16(12, 32)
	file.encode_u32(14, 1)
	file.encode_u16(18, 100)
	file.encode_u8(34, 1)
	file.encode_u8(35, 1)
	file.append_array(frame)
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null: return false
	output.store_buffer(file)
	return output.get_error() == OK

func _chunk(chunk_type: int, data: PackedByteArray) -> PackedByteArray:
	var chunk := PackedByteArray()
	_u32(chunk, data.size() + 6)
	_u16(chunk, chunk_type)
	chunk.append_array(data)
	return chunk

func _string(target: PackedByteArray, value: String) -> void:
	var bytes := value.to_utf8_buffer()
	_u16(target, bytes.size())
	target.append_array(bytes)

func _u16(target: PackedByteArray, value: int) -> void:
	target.append(value & 255)
	target.append((value >> 8) & 255)

func _u32(target: PackedByteArray, value: int) -> void:
	for shift in [0, 8, 16, 24]: target.append((value >> shift) & 255)
