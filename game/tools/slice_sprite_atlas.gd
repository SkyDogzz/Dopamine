extends SceneTree

const COLUMNS := 4
const ROWS := 4
const OUTPUT_SIZE := 64
const PADDING := 4
const ATLAS_JOBS := [
	{"source": "res://assets/sprites/dopamine_atlas_source.png", "output": "res://assets/sprites", "names": [
	"player_cyan", "enemy_chaser", "enemy_sprinter", "enemy_tank",
	"enemy_shooter", "boss_mid_placeholder", "boss_final_placeholder", "xp_orb",
	"projectile_lightning", "projectile_inferno", "projectile_crimson", "projectile_enemy",
	"chest_closed", "relic_storm_core", "relic_infernal_heart", "relic_blood_chalice",
	]},
	{"source": "res://assets/icons/progression_atlas_source.png", "output": "res://assets/icons", "names": [
	"equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots",
	"equipment_amulet", "equipment_ring", "resource_essence", "resource_powder",
	"rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary",
	"rarity_mythic", "skill_node", "achievement_medal", "run_record",
	]},
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for job in ATLAS_JOBS:
		if not _slice_atlas(job):
			quit(1)
			return
	quit()

func _slice_atlas(job: Dictionary) -> bool:
	var source := Image.new()
	var error := source.load(job["source"])
	if error != OK:
		push_error("Could not load atlas %s: %s" % [job["source"], error])
		return false
	if source.get_format() != Image.FORMAT_RGBA8:
		push_error("Atlas must preserve RGBA transparency: %s" % job["source"])
		return false
	var names: Array = job["names"]
	if names.size() != COLUMNS * ROWS:
		push_error("Atlas must have 16 named cells: %s" % job["source"])
		return false
	var output_directory := ProjectSettings.globalize_path(job["output"])
	DirAccess.make_dir_recursive_absolute(output_directory)
	for index in range(names.size()):
		var column := index % COLUMNS
		var row := index / COLUMNS
		var left := roundi(float(column) * source.get_width() / COLUMNS)
		var top := roundi(float(row) * source.get_height() / ROWS)
		var right := roundi(float(column + 1) * source.get_width() / COLUMNS)
		var bottom := roundi(float(row + 1) * source.get_height() / ROWS)
		var cell := source.get_region(Rect2i(left, top, right - left, bottom - top))
		var bounds := _alpha_bounds(cell)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("Sprite cell %d is empty" % index)
			return false
		var content := cell.get_region(bounds)
		var fit_size := OUTPUT_SIZE - PADDING * 2
		var scale := minf(float(fit_size) / content.get_width(), float(fit_size) / content.get_height())
		var resized_width := maxi(1, roundi(content.get_width() * scale))
		var resized_height := maxi(1, roundi(content.get_height() * scale))
		content.resize(resized_width, resized_height, Image.INTERPOLATE_NEAREST)
		var sprite := Image.create(OUTPUT_SIZE, OUTPUT_SIZE, false, Image.FORMAT_RGBA8)
		sprite.fill(Color.TRANSPARENT)
		var destination := Vector2i((OUTPUT_SIZE - resized_width) / 2, (OUTPUT_SIZE - resized_height) / 2)
		sprite.blit_rect(content, Rect2i(Vector2i.ZERO, content.get_size()), destination)
		var output_path := output_directory.path_join("%s.png" % names[index])
		error = sprite.save_png(output_path)
		if error != OK:
			push_error("Could not write %s: %s" % [output_path, error])
			return false
		print("%s: %dx%d source, alpha bounds %s" % [names[index], cell.get_width(), cell.get_height(), bounds])
	return true

func _alpha_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)
