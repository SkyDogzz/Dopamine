extends SceneTree

const REFERENCE := "res://assets/source/environment/ground_quiet_reference.png"
const OUTPUT := "res://assets/sprites/environment/survival_ground_pixel.png"
const SOURCE := "res://assets/source/environment/survival_ground_pixel.aseprite"
const PALETTE := ["#10152B", "#1B2340", "#293354", "#37314F", "#075A80", "#158C62"]
const BASE := Color("#10152B")
const SIZE := 256

func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(REFERENCE))
	if image.is_empty():
		push_error("Could not load generated ground reference")
		quit(1)
		return
	image.resize(SIZE / 2, SIZE / 2, Image.INTERPOLATE_BILINEAR)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			image.set_pixel(x, y, _nearest(image.get_pixel(x, y).lerp(BASE, 0.68)))
	_make_seamless(image, 8)
	image.resize(SIZE, SIZE, Image.INTERPOLATE_NEAREST)
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	var source_path := ProjectSettings.globalize_path(SOURCE)
	if image.save_png(output_path) != OK or not _save_aseprite(image, source_path, "survival_ground_pixel"):
		push_error("Could not save the active pixel-art ground and editable source")
		quit(1)
		return
	print("Built quiet seamless Survival ground: 256x256, six Art Bible colors, editable Aseprite source")
	quit()

func _make_seamless(image: Image, edge_width: int) -> void:
	for offset in range(edge_width):
		var amount := 1.0 - float(offset) / float(edge_width)
		for index in range(image.get_height()):
			var left := image.get_pixel(offset, index)
			var right := image.get_pixel(image.get_width() - 1 - offset, index)
			var average := (left + right) * 0.5
			image.set_pixel(offset, index, _nearest(left.lerp(average, amount)))
			image.set_pixel(image.get_width() - 1 - offset, index, _nearest(right.lerp(average, amount)))
	for offset in range(edge_width):
		var amount := 1.0 - float(offset) / float(edge_width)
		for index in range(image.get_width()):
			var top := image.get_pixel(index, offset)
			var bottom := image.get_pixel(index, image.get_height() - 1 - offset)
			var average := (top + bottom) * 0.5
			image.set_pixel(index, offset, _nearest(top.lerp(average, amount)))
			image.set_pixel(index, image.get_height() - 1 - offset, _nearest(bottom.lerp(average, amount)))

func _nearest(pixel: Color) -> Color:
	var best := BASE
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
