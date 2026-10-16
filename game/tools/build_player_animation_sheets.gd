extends SceneTree

const REFERENCES := {
	"idle": "res://assets/source/pilot/player_idle_reference.png",
	"walk": "res://assets/source/pilot/player_walk_reference.png",
}
const PALETTE := [
	"#080B18", "#10152B", "#1B2340", "#293354", "#37314F", "#59476F", "#075A80", "#087FB2",
	"#0EB8D4", "#37E8F5", "#7623A8", "#826999", "#AD91BB", "#E13ACB", "#FFD447", "#FFF19A",
]
const FRAME_SIZE := 32
const DIRECTIONS := 4

func _initialize() -> void:
	for animation in REFERENCES:
		var reference := Image.load_from_file(ProjectSettings.globalize_path(REFERENCES[animation]))
		if reference.is_empty():
			push_error("Could not load player %s reference sheet" % animation)
			quit(1)
			return
		var sheet := Image.create(FRAME_SIZE * DIRECTIONS, FRAME_SIZE * DIRECTIONS, false, Image.FORMAT_RGBA8)
		sheet.fill(Color.TRANSPARENT)
		for row in range(DIRECTIONS):
			for column in range(DIRECTIONS):
				var left := roundi(float(column) * reference.get_width() / DIRECTIONS)
				var top := roundi(float(row) * reference.get_height() / DIRECTIONS)
				var right := roundi(float(column + 1) * reference.get_width() / DIRECTIONS)
				var bottom := roundi(float(row + 1) * reference.get_height() / DIRECTIONS)
				var frame := reference.get_region(Rect2i(left, top, right - left, bottom - top))
				frame.resize(FRAME_SIZE, FRAME_SIZE, Image.INTERPOLATE_NEAREST)
				for y in range(FRAME_SIZE):
					for x in range(FRAME_SIZE):
						var pixel := frame.get_pixel(x, y)
						if pixel.a < 0.5:
							frame.set_pixel(x, y, Color.TRANSPARENT)
						else:
							frame.set_pixel(x, y, _nearest_palette_color(pixel))
				sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(column * FRAME_SIZE, row * FRAME_SIZE))
		var png_path := "res://assets/sprites/player_%s.png" % animation
		var ase_path := "res://assets/source/pilot/player_%s.aseprite" % animation
		if sheet.save_png(ProjectSettings.globalize_path(png_path)) != OK or not _save_aseprite(sheet, ProjectSettings.globalize_path(ase_path), "player_%s" % animation):
			push_error("Could not save player %s sprite sheet" % animation)
			quit(1)
			return
	print("Built transparent player idle/walk sheets: four 32x32 frames in each of four direction rows, 16-color palette")
	quit()

func _nearest_palette_color(pixel: Color) -> Color:
	var best := Color.BLACK
	var best_distance := INF
	for hex in PALETTE:
		var candidate := Color(hex)
		var distance := pixel.r * 0.299 * pow(candidate.r - pixel.r, 2.0) + pixel.g * 0.587 * pow(candidate.g - pixel.g, 2.0) + pixel.b * 0.114 * pow(candidate.b - pixel.b, 2.0)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func _save_aseprite(image: Image, path: String, layer_name: String) -> bool:
	var layer := PackedByteArray()
	for value in [3, 0, 0, 0, 0, 0]: _u16(layer, value)
	layer.append(255)
	layer.append_array([0, 0, 0])
	_string(layer, layer_name)
	var chunks := _chunk(0x2004, layer)
	var cel := PackedByteArray()
	for value in [0, 0, 0]: _u16(cel, value)
	cel.append(255)
	_u16(cel, 0)
	_u16(cel, 0)
	cel.append_array([0, 0, 0, 0, 0])
	_u16(cel, image.get_width())
	_u16(cel, image.get_height())
	cel.append_array(image.get_data())
	chunks.append_array(_chunk(0x2005, cel))
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
	if output == null:
		return false
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
