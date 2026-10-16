extends SceneTree

const SOURCE := "res://assets/source/pilot/generated_reference.png"
const PALETTE := ["#080B18", "#10152B", "#1B2340", "#293354", "#37314F", "#59476F", "#826999", "#AD91BB", "#075A80", "#087FB2", "#0EB8D4", "#37E8F5", "#7623A8", "#E13ACB", "#FFD447", "#FFF19A"]
const REGIONS := {
	"player_cyan": [0.03, 0.04, 0.27, 0.90, 32],
	"enemy_chaser": [0.29, 0.10, 0.53, 0.86, 24],
	"projectile_lightning": [0.55, 0.25, 0.72, 0.72, 16],
}

func _initialize() -> void:
	var source_texture := load(SOURCE) as Texture2D
	if source_texture == null:
		push_error("Missing generated reference: %s" % SOURCE)
		quit(1)
		return
	var source := source_texture.get_image()
	for asset_name in REGIONS:
		if not _build_asset(source, asset_name, REGIONS[asset_name]):
			quit(1)
			return
	print("Built three palette-limited pilot sprites and editable Aseprite files")
	quit()

func _build_asset(source: Image, asset_name: String, spec: Array) -> bool:
	var region := Rect2i(int(source.get_width() * spec[0]), int(source.get_height() * spec[1]), int(source.get_width() * (spec[2] - spec[0])), int(source.get_height() * (spec[3] - spec[1])))
	var bounds := _alpha_bounds(source, region)
	if bounds.size == Vector2i.ZERO:
		push_error("Generated region is transparent: %s" % asset_name)
		return false
	var crop := source.get_region(bounds)
	var size := int(spec[4])
	var scale := minf(float(size) / crop.get_width(), float(size) / crop.get_height())
	var draw_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_NEAREST)
	var result := Image.create(size, size, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var offset := (Vector2i(size, size) - draw_size) / 2
	for y in range(draw_size.y):
		for x in range(draw_size.x):
			var pixel := crop.get_pixel(x, y)
			if pixel.a > 0.5:
				result.set_pixel(x + offset.x, y + offset.y, _nearest_palette_color(pixel))
	var png_path := "res://assets/sprites/%s.png" % asset_name
	var ase_path := "res://assets/source/pilot/%s.aseprite" % asset_name
	if result.save_png(png_path) != OK or not _save_aseprite(result, ase_path, asset_name):
		push_error("Could not save pilot asset %s" % asset_name)
		return false
	return true

func _alpha_bounds(image: Image, region: Rect2i) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in range(region.position.y, mini(image.get_height(), region.end.y)):
		for x in range(region.position.x, mini(image.get_width(), region.end.x)):
			if image.get_pixel(x, y).a > 0.5:
				left = mini(left, x)
				top = mini(top, y)
				right = maxi(right, x)
				bottom = maxi(bottom, y)
	return Rect2i(left, top, right - left + 1, bottom - top + 1) if right >= left else Rect2i()

func _nearest_palette_color(pixel: Color) -> Color:
	var best := Color.BLACK
	var best_distance := INF
	for hex in PALETTE:
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
