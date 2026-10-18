extends SceneTree

const ROSTER_REFERENCE := "res://assets/source/roster/generated_reference.png"
const ROSTER_NAMES := ["enemy_chaser", "enemy_sprinter", "enemy_tank", "enemy_shooter", "enemy_buffer", "enemy_exploder", "enemy_shielder", "enemy_summoner", "enemy_summoned", "elite_sprinter", "boss_mid_placeholder", "boss_final_placeholder"]
const RETIRED_ROSTER_COUNT := 9
const VFX_REFERENCE := "res://assets/source/vfx/weapon_impacts_reference.png"
const IMPACT_NAMES := ["impact_spark", "impact_star", "impact_slash", "impact_pop", "impact_ring", "impact_burst", "impact_shards", "impact_shock_ring", "impact_angular", "impact_evolved"]
const GROUND_REFERENCE := "res://assets/source/environment/ground_candidate_reference.png"
const RUINS_REFERENCE := "res://assets/source/environment/ruins_candidate_reference.png"

func _initialize() -> void:
	var roster_texture := load(ROSTER_REFERENCE) as Texture2D
	if roster_texture == null:
		push_error("Missing generated roster reference: %s" % ROSTER_REFERENCE)
		quit(1)
		return
	var roster_source := roster_texture.get_image()
	var roster_cell_width := roster_source.get_width() / 4
	var roster_cell_height := roster_source.get_height() / 3
	for index in range(RETIRED_ROSTER_COUNT, ROSTER_NAMES.size()):
		var rect := Rect2i((index % 4) * roster_cell_width, floori(float(index) / 4.0) * roster_cell_height, roster_cell_width, roster_cell_height)
		var background := roster_source.get_pixel(rect.position.x + 4, rect.position.y + 4)
		var sprite_size := 96 if ROSTER_NAMES[index].begins_with("boss_") else 24
		if not _export_crop(roster_source, rect, background, ROSTER_NAMES[index], "res://assets/sprites/roster", "res://assets/source/roster", sprite_size):
			quit(1)
			return
	var vfx_texture := load(VFX_REFERENCE) as Texture2D
	if vfx_texture == null:
		push_error("Missing generated VFX reference: %s" % VFX_REFERENCE)
		quit(1)
		return
	var vfx_source := vfx_texture.get_image()
	var impact_cell_width := vfx_source.get_width() / 5
	var impact_cell_height := vfx_source.get_height() / 2
	var impact_atlas := Image.create(IMPACT_NAMES.size() * 64, 64, false, Image.FORMAT_RGBA8)
	impact_atlas.fill(Color.TRANSPARENT)
	for index in range(IMPACT_NAMES.size()):
		var rect := Rect2i((index % 5) * impact_cell_width, floori(float(index) / 5.0) * impact_cell_height, impact_cell_width, impact_cell_height)
		var content_rect := Rect2i(rect.position + Vector2i(10, 10), rect.size - Vector2i(20, 20))
		var background := vfx_source.get_pixel(content_rect.position.x + 4, content_rect.position.y + 4)
		if not _export_crop(vfx_source, content_rect, background, IMPACT_NAMES[index], "res://assets/sprites/vfx", "res://assets/source/vfx", 64):
			quit(1)
			return
		var exported := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/vfx/%s.png" % IMPACT_NAMES[index]))
		impact_atlas.blit_rect(exported, Rect2i(Vector2i.ZERO, exported.get_size()), Vector2i(index * 64, 0))
	if impact_atlas.save_png("res://assets/sprites/weapon_impacts_pixel.png") != OK:
		push_error("Could not save the horizontal impact atlas")
		quit(1)
		return
	var ground_texture := load(GROUND_REFERENCE) as Texture2D
	if ground_texture == null:
		push_error("Missing generated ground candidate reference: %s" % GROUND_REFERENCE)
		quit(1)
		return
	var ground := ground_texture.get_image()
	ground.resize(64, 64, Image.INTERPOLATE_BILINEAR)
	ground.resize(256, 256, Image.INTERPOLATE_NEAREST)
	for y in range(ground.get_height()):
		for x in range(ground.get_width()):
			ground.set_pixel(x, y, _nearest_palette_color(ground.get_pixel(x, y)))
	if ground.save_png("res://assets/sprites/environment/ground_moss_stone_candidate.png") != OK or not _save_aseprite(ground, "res://assets/source/environment/ground_moss_stone_candidate.aseprite", "ground_moss_stone_candidate"):
		push_error("Could not save the palette-limited ground candidate")
		quit(1)
		return
	var ruins_texture := load(RUINS_REFERENCE) as Texture2D
	if ruins_texture == null:
		push_error("Missing generated ruins candidate reference: %s" % RUINS_REFERENCE)
		quit(1)
		return
	var ruins := ruins_texture.get_image()
	ruins.resize(512, 512, Image.INTERPOLATE_NEAREST)
	ruins.resize(1536, 1536, Image.INTERPOLATE_NEAREST)
	for y in range(ruins.get_height()):
		for x in range(ruins.get_width()):
			var pixel := ruins.get_pixel(x, y)
			ruins.set_pixel(x, y, Color.TRANSPARENT if pixel.a < 0.5 else _nearest_palette_color(pixel))
	if ruins.save_png("res://assets/sprites/environment/survival_ruins_pixel.png") != OK or not _save_aseprite(ruins, "res://assets/source/environment/survival_ruins_pixel.aseprite", "survival_ruins_pixel"):
		push_error("Could not save the palette-limited ruins candidate")
		quit(1)
		return
	print("Built legacy roster prototypes, VFX and environment candidates with editable Aseprite sources")
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
