extends SceneTree

func _initialize() -> void:
	push_error("Retired reference-sheet builder: use generate_original_visuals.gd and the dedicated family generators instead.")
	quit()

func _export_crop(source: Image, rect: Rect2i, background: Color, name: String, output_dir: String, source_dir: String, output_size: int = OUTPUT_SIZE) -> bool:
	var left := rect.end.x
	var top := rect.end.y
	var right := rect.position.x - 1
	var bottom := rect.position.y - 1
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if _color_distance_squared(source.get_pixel(x, y), background) > 0.025:
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
	if right < left:
		push_error("Empty cell in generated reference: %s" % name)
		return false
	var crop := source.get_region(Rect2i(left, top, right - left + 1, bottom - top + 1))
	var scale := minf(float(output_size - 4) / crop.get_width(), float(output_size - 4) / crop.get_height())
	var draw_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_NEAREST)
	var result := Image.create(output_size, output_size, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var offset := (Vector2i(output_size, output_size) - draw_size) / 2
	for y in range(draw_size.y):
		for x in range(draw_size.x):
			var color := crop.get_pixel(x, y)
			if _color_distance_squared(color, background) > 0.025:
				result.set_pixel(x + offset.x, y + offset.y, _nearest_palette_color(color))
	var png_path := "%s/%s.png" % [output_dir, name]
	var ase_path := "%s/%s.aseprite" % [source_dir, name]
	if result.save_png(png_path) != OK or not _save_aseprite(result, ase_path, name):
		push_error("Could not save catalog icon %s" % name)
		return false
	return true

func _nearest_palette_color(pixel: Color) -> Color:
	return _nearest_palette_color_from(pixel, PALETTE)

func _nearest_palette_color_from(pixel: Color, palette: Array) -> Color:
	var best := Color.BLACK
	var best_distance := INF
	for hex in palette:
		var candidate := Color.from_string(hex, Color.BLACK)
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
	var layer_chunk := _chunk(0x2004, layer)
	var cel := PackedByteArray()
	for value in [0, 0, 0]: _u16(cel, value)
	cel.append(255)
	_u16(cel, 0)
	_u16(cel, 0)
	cel.append_array([0, 0, 0, 0, 0])
	_u16(cel, image.get_width())
	_u16(cel, image.get_height())
	cel.append_array(image.get_data())
	var chunks := layer_chunk + _chunk(0x2005, cel)
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
