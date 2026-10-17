extends SceneTree

const SOURCE := "res://../docs/art/source/pulse_warden_generated.png"
const OUTPUT := "res://assets/sprites/roster/boss_pulse_warden.png"
const EDITABLE_SOURCE := "res://assets/source/roster/boss_pulse_warden.aseprite"
const OUTPUT_SIZE := 96
const PALETTE := [
	"#080B18", "#10152B", "#1B2340", "#075A80", "#087FB2", "#0EB8D4",
	"#37E8F5", "#7623A8", "#A52DCA", "#E13ACB", "#FF75E3", "#A85B19",
	"#E69825", "#FFD447", "#FFF19A", "#F6F7FF",
]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty():
		push_error("Could not load generated Pulse Warden source")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	_remove_checker_background(source)
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		push_error("Generated Pulse Warden source is fully transparent")
		quit(1)
		return
	var crop := source.get_region(bounds)
	var scale := minf(float(OUTPUT_SIZE) / crop.get_width(), float(OUTPUT_SIZE) / crop.get_height())
	var draw_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_NEAREST)
	var result := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var palette: Array[Color] = []
	for hex_color in PALETTE:
		palette.append(Color.html(hex_color))
	var colors_used: Dictionary = {}
	var offset := (Vector2i(OUTPUT_SIZE, OUTPUT_SIZE) - draw_size) / 2
	for y in range(draw_size.y):
		for x in range(draw_size.x):
			var pixel := crop.get_pixel(x, y)
			if pixel.a <= 0.5:
				continue
			var color := _nearest_palette_color(pixel, palette)
			result.set_pixel(offset.x + x, offset.y + y, color)
			colors_used[color.to_html(false)] = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites/roster"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/source/roster"))
	if result.save_png(OUTPUT) != OK or not _save_aseprite(result, ProjectSettings.globalize_path(EDITABLE_SOURCE), "boss_pulse_warden"):
		push_error("Could not write the Pulse Warden exports")
		quit(1)
		return
	print("Built Pulse Warden prototype: %dx%d, %d master palette colors, alpha preserved" % [OUTPUT_SIZE, OUTPUT_SIZE, colors_used.size()])
	quit()

func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.5:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE) if maximum.x >= minimum.x else Rect2i()

func _remove_checker_background(image: Image) -> void:
	var visited := PackedByteArray()
	visited.resize(image.get_width() * image.get_height())
	var queue: Array[Vector2i] = []
	for point in [Vector2i.ZERO, Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), image.get_size() - Vector2i.ONE]:
		if _is_checker_color(image.get_pixelv(point)):
			queue.append(point)
	while not queue.is_empty():
		var point: Vector2i = queue.pop_back()
		var index := point.y * image.get_width() + point.x
		if visited[index] == 1:
			continue
		visited[index] = 1
		if not _is_checker_color(image.get_pixelv(point)):
			continue
		image.set_pixelv(point, Color.TRANSPARENT)
		for offset_value in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
			var offset: Vector2i = offset_value
			var neighbor: Vector2i = point + offset
			if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < image.get_width() and neighbor.y < image.get_height():
				var neighbor_index: int = neighbor.y * image.get_width() + neighbor.x
				if visited[neighbor_index] == 0:
					queue.append(neighbor)

func _is_checker_color(color: Color) -> bool:
	return color.r > 0.68 and color.g > 0.68 and color.b > 0.68 and maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < 0.12

func _nearest_palette_color(pixel: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var distance := pixel.r * 0.299 * pow(candidate.r - pixel.r, 2.0) + \
			pixel.g * 0.587 * pow(candidate.g - pixel.g, 2.0) + \
			pixel.b * 0.114 * pow(candidate.b - pixel.b, 2.0)
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
