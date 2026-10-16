extends SceneTree

const REFERENCE := "res://assets/source/catalog_weapons/generated_reference.png"
const SOURCE_DIR := "res://assets/source/catalog_weapons"
const OUTPUT_DIR := "res://assets/sprites/catalog"
const RELIC_REFERENCE := "res://assets/source/catalog_relics/generated_reference.png"
const RELIC_SOURCE_DIR := "res://assets/source/catalog_relics"
const RELICS := ["storm_core", "infernal_heart", "blood_chalice", "celestial_eye", "frozen_crown", "magnet_heart", "magnetic_coil", "overdrive_engine", "plague_mask", "prism_crystal", "singularity"]
const UI_REFERENCE := "res://assets/source/catalog_ui/generated_reference.png"
const UI_SOURCE_DIR := "res://assets/source/catalog_ui"
const UI_ICONS := ["equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots", "equipment_amulet", "equipment_ring", "rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary", "rarity_mythic", "resource_essence", "resource_powder", "skill_node", "achievement_medal", "run_record"]
const WEAPONS := [
	"lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud",
	"sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova",
]
const PALETTE := ["#080B18", "#10152B", "#1B2340", "#293354", "#37314F", "#59476F", "#826999", "#AD91BB", "#075A80", "#087FB2", "#0EB8D4", "#37E8F5", "#7623A8", "#E13ACB", "#FFD447", "#FFF19A"]
const OUTPUT_SIZE := 32

func _initialize() -> void:
	var texture := load(REFERENCE) as Texture2D
	if texture == null:
		push_error("Missing generated weapon reference: %s" % REFERENCE)
		quit(1)
		return
	var source := texture.get_image()
	var cell_width := source.get_width() / 5
	var cell_height := source.get_height() / 4
	for index in range(WEAPONS.size()):
		for evolution in [false, true]:
			var row: int = floori(float(index) / 5.0) + (2 if evolution else 0)
			var column := index % 5
			var rect := Rect2i(column * cell_width, row * cell_height, cell_width, cell_height)
			var name: String = ("evolution_" if evolution else "weapon_") + WEAPONS[index]
			if not _export_cell(source, rect, name):
				quit(1)
				return
	var relic_texture := load(RELIC_REFERENCE) as Texture2D
	if relic_texture == null:
		push_error("Missing generated relic reference: %s" % RELIC_REFERENCE)
		quit(1)
		return
	var relic_source := relic_texture.get_image()
	var relic_cell_width := relic_source.get_width() / 4
	var relic_cell_height := relic_source.get_height() / 3
	for index in range(RELICS.size()):
		var rect := Rect2i((index % 4) * relic_cell_width, floori(float(index) / 4.0) * relic_cell_height, relic_cell_width, relic_cell_height)
		if not _export_relic_cell(relic_source, rect, RELICS[index]):
			quit(1)
			return
	var ui_texture := load(UI_REFERENCE) as Texture2D
	if ui_texture == null:
		push_error("Missing generated UI reference: %s" % UI_REFERENCE)
		quit(1)
		return
	var ui_source := ui_texture.get_image()
	var ui_cell_width := ui_source.get_width() / 4
	var ui_cell_height := ui_source.get_height() / 4
	for index in range(UI_ICONS.size()):
		var rect := Rect2i((index % 4) * ui_cell_width, floori(float(index) / 4.0) * ui_cell_height, ui_cell_width, ui_cell_height)
		var content_rect := Rect2i(rect.position + Vector2i(8, 8), rect.size - Vector2i(16, 16))
		var background := ui_source.get_pixel(content_rect.position.x + 4, content_rect.position.y + 4)
		if not _export_crop(ui_source, content_rect, background, UI_ICONS[index], "res://assets/icons/catalog", UI_SOURCE_DIR):
			quit(1)
			return
	print("Built 20 weapon/evolution, 11 relic and 16 UI icons with editable Aseprite sources")
	quit()

func _export_cell(source: Image, rect: Rect2i, name: String) -> bool:
	var background := source.get_pixel(0, 0)
	return _export_crop(source, rect, background, name, OUTPUT_DIR, SOURCE_DIR)

func _export_relic_cell(source: Image, rect: Rect2i, name: String) -> bool:
	var content_rect := Rect2i(rect.position + Vector2i(8, 8), rect.size - Vector2i(16, 16))
	var background := source.get_pixel(content_rect.position.x + 4, content_rect.position.y + 4)
	return _export_crop(source, content_rect, background, "relic_" + name, OUTPUT_DIR, RELIC_SOURCE_DIR)

func _export_crop(source: Image, rect: Rect2i, background: Color, name: String, output_dir: String, source_dir: String) -> bool:
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
	var scale := minf(float(OUTPUT_SIZE - 4) / crop.get_width(), float(OUTPUT_SIZE - 4) / crop.get_height())
	var draw_size := Vector2i(maxi(1, roundi(crop.get_width() * scale)), maxi(1, roundi(crop.get_height() * scale)))
	crop.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_NEAREST)
	var result := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var offset := (Vector2i(OUTPUT_SIZE, OUTPUT_SIZE) - draw_size) / 2
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

func _color_distance_squared(a: Color, b: Color) -> float:
	return pow(a.r - b.r, 2.0) + pow(a.g - b.g, 2.0) + pow(a.b - b.b, 2.0)

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
