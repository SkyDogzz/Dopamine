extends SceneTree

const REFERENCE := "res://assets/source/catalog_weapons/generated_reference.png"
const SOURCE_DIR := "res://assets/source/catalog_weapons"
const OUTPUT_DIR := "res://assets/sprites/catalog"
const DEDICATED_ICON_REFERENCES := {
	"weapon_lightning_conductor": "res://assets/source/catalog_weapons/weapon_lightning_conductor_reference.png",
	"weapon_inferno_sprayer": "res://assets/source/catalog_weapons/weapon_inferno_sprayer_reference.png",
	"weapon_crimson_daggers": "res://assets/source/catalog_weapons/weapon_crimson_daggers_reference.png",
	"weapon_minigun": "res://assets/source/catalog_weapons/weapon_minigun_reference.png",
	"weapon_toxic_cloud": "res://assets/source/catalog_weapons/weapon_toxic_cloud_reference.png",
	"weapon_sawblades": "res://assets/source/catalog_weapons/weapon_sawblades_reference.png",
	"weapon_meteor_staff": "res://assets/source/catalog_weapons/weapon_meteor_staff_reference.png",
	"weapon_prism_laser": "res://assets/source/catalog_weapons/weapon_prism_laser_reference.png",
	"weapon_void_orb": "res://assets/source/catalog_weapons/weapon_void_orb_reference.png",
	"weapon_frost_nova": "res://assets/source/catalog_weapons/weapon_frost_nova_reference.png",
	"evolution_lightning_conductor": "res://assets/source/catalog_weapons/evolution_lightning_conductor_reference.png",
	"evolution_inferno_sprayer": "res://assets/source/catalog_weapons/evolution_inferno_sprayer_reference.png",
	"evolution_crimson_daggers": "res://assets/source/catalog_weapons/evolution_crimson_daggers_reference.png",
	"evolution_void_orb": "res://assets/source/catalog_weapons/evolution_void_orb_reference.png",
	"evolution_frost_nova": "res://assets/source/catalog_weapons/evolution_frost_nova_reference.png",
	"evolution_minigun": "res://assets/source/catalog_weapons/evolution_minigun_reference.png",
	"evolution_toxic_cloud": "res://assets/source/catalog_weapons/evolution_toxic_cloud_reference.png",
	"evolution_sawblades": "res://assets/source/catalog_weapons/evolution_sawblades_reference.png",
	"evolution_meteor_staff": "res://assets/source/catalog_weapons/evolution_meteor_staff_reference.png",
	"evolution_prism_laser": "res://assets/source/catalog_weapons/evolution_prism_laser_reference.png",
	"relic_storm_core": "res://assets/source/catalog_relics/relic_storm_core_reference.png",
	"relic_infernal_heart": "res://assets/source/catalog_relics/relic_infernal_heart_reference.png",
	"relic_blood_chalice": "res://assets/source/catalog_relics/relic_blood_chalice_reference.png",
	"relic_celestial_eye": "res://assets/source/catalog_relics/relic_celestial_eye_reference.png",
	"relic_frozen_crown": "res://assets/source/catalog_relics/relic_frozen_crown_reference.png",
	"relic_magnetic_coil": "res://assets/source/catalog_relics/relic_magnetic_coil_reference.png",
	"relic_overdrive_engine": "res://assets/source/catalog_relics/relic_overdrive_engine_reference.png",
	"relic_plague_mask": "res://assets/source/catalog_relics/relic_plague_mask_reference.png",
	"relic_prism_crystal": "res://assets/source/catalog_relics/relic_prism_crystal_reference.png",
	"relic_singularity": "res://assets/source/catalog_relics/relic_singularity_reference.png",
	"relic_magnet_heart": "res://assets/source/catalog_relics/relic_magnet_heart_reference.png",
}
const RELIC_REFERENCE := "res://assets/source/catalog_relics/generated_reference.png"
const RELIC_SOURCE_DIR := "res://assets/source/catalog_relics"
const RELICS := ["storm_core", "infernal_heart", "blood_chalice", "celestial_eye", "frozen_crown", "magnet_heart", "magnetic_coil", "overdrive_engine", "plague_mask", "prism_crystal", "singularity"]
const UI_REFERENCE := "res://assets/source/catalog_ui/generated_reference.png"
const UI_SOURCE_DIR := "res://assets/source/catalog_ui"
const UI_ICONS := ["equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots", "equipment_amulet", "equipment_ring", "rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary", "rarity_mythic", "resource_essence", "resource_powder", "skill_node", "achievement_medal", "run_record"]
const ROSTER_REFERENCE := "res://assets/source/roster/generated_reference.png"
const ROSTER_NAMES := ["enemy_chaser", "enemy_sprinter", "enemy_tank", "enemy_shooter", "enemy_buffer", "enemy_exploder", "enemy_shielder", "enemy_summoner", "enemy_summoned", "elite_sprinter", "boss_mid_placeholder", "boss_final_placeholder"]
const RETIRED_ROSTER_COUNT := 9
const VFX_REFERENCE := "res://assets/source/vfx/weapon_impacts_reference.png"
const IMPACT_NAMES := ["impact_spark", "impact_star", "impact_slash", "impact_pop", "impact_ring", "impact_burst", "impact_shards", "impact_shock_ring", "impact_angular", "impact_evolved"]
const GROUND_REFERENCE := "res://assets/source/environment/ground_candidate_reference.png"
const RUINS_REFERENCE := "res://assets/source/environment/ruins_candidate_reference.png"
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
	for icon_name in DEDICATED_ICON_REFERENCES:
		var reference_texture := load(DEDICATED_ICON_REFERENCES[icon_name]) as Texture2D
		var source_dir := RELIC_SOURCE_DIR if icon_name.begins_with("relic_") else SOURCE_DIR
		if reference_texture == null or not _export_transparent(
			reference_texture.get_image(), icon_name, OUTPUT_SIZE, PALETTE, OUTPUT_DIR, source_dir
		):
			push_error("Could not export catalog icon %s from its dedicated reference" % icon_name)
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
	print("Built catalog/UI/roster icons, VFX and environment assets with editable Aseprite sources")
	quit()

func _export_cell(source: Image, rect: Rect2i, name: String) -> bool:
	var background := source.get_pixel(0, 0)
	return _export_crop(source, rect, background, name, OUTPUT_DIR, SOURCE_DIR)

func _export_relic_cell(source: Image, rect: Rect2i, name: String) -> bool:
	var content_rect := Rect2i(rect.position + Vector2i(8, 8), rect.size - Vector2i(16, 16))
	var background := source.get_pixel(content_rect.position.x + 4, content_rect.position.y + 4)
	return _export_crop(source, content_rect, background, "relic_" + name, OUTPUT_DIR, RELIC_SOURCE_DIR)

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

func _export_transparent(
	source: Image,
	name: String,
	output_size: int,
	palette: Array,
	output_dir: String = "res://assets/sprites/rewards",
	source_dir: String = "res://assets/source/rewards"
) -> bool:
	var left := source.get_width()
	var top := source.get_height()
	var right := -1
	var bottom := -1
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			if source.get_pixel(x, y).a < 0.5:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left:
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
			var pixel := crop.get_pixel(x, y)
			if pixel.a >= 0.5:
				result.set_pixel(x + offset.x, y + offset.y, _nearest_palette_color_from(pixel, palette))
	return result.save_png("%s/%s.png" % [output_dir, name]) == OK and _save_aseprite(result, "%s/%s.aseprite" % [source_dir, name], name)

func _color_distance_squared(a: Color, b: Color) -> float:
	return pow(a.r - b.r, 2.0) + pow(a.g - b.g, 2.0) + pow(a.b - b.b, 2.0)

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
