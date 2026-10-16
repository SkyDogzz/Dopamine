extends SceneTree

const WEAPONS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
const RELICS := ["storm_core", "infernal_heart", "blood_chalice", "celestial_eye", "frozen_crown", "magnet_heart", "magnetic_coil", "overdrive_engine", "plague_mask", "prism_crystal", "singularity"]
const UI_ICONS := ["equipment_helmet", "equipment_armor", "equipment_gloves", "equipment_boots", "equipment_amulet", "equipment_ring", "rarity_normal", "rarity_magic", "rarity_mystic", "rarity_legendary", "rarity_mythic", "resource_essence", "resource_powder", "skill_node", "achievement_medal", "run_record"]
const ROSTER := ["enemy_chaser", "enemy_sprinter", "enemy_tank", "enemy_shooter", "enemy_buffer", "enemy_exploder", "enemy_shielder", "enemy_summoner", "enemy_summoned", "elite_sprinter", "boss_mid_placeholder", "boss_final_placeholder"]
const IMPACTS := ["impact_spark", "impact_star", "impact_slash", "impact_pop", "impact_ring", "impact_burst", "impact_shards", "impact_shock_ring", "impact_angular", "impact_evolved"]
const PROJECTILES := ["projectile_lightning", "projectile_inferno", "projectile_crimson", "projectile_enemy", "projectile_minigun", "projectile_toxic_cloud", "projectile_sawblades", "projectile_meteor", "projectile_starfall_fragment", "projectile_prism_laser", "projectile_prism_secondary", "projectile_void_orb", "projectile_frost_nova", "projectile_infinite_circuit", "projectile_wildfire", "projectile_bloodstorm", "projectile_event_horizon", "projectile_absolute_zero", "projectile_pandemic", "projectile_razorstorm", "projectile_starfall", "projectile_spectrum_collapse", "projectile_unique_lightning_burst", "projectile_evolution_shockwave"]

func _initialize() -> void:
	for weapon_id in WEAPONS:
		if not _check_icon("weapon_" + weapon_id) or not _check_icon("evolution_" + weapon_id):
			quit(1)
			return
	for relic_id in RELICS:
		if not _check_icon("relic_" + relic_id):
			quit(1)
			return
	for icon_name in UI_ICONS:
		if not _check_icon(icon_name):
			quit(1)
			return
	for sprite_name in ROSTER:
		if not _check_icon(sprite_name):
			quit(1)
			return
	for impact_name in IMPACTS:
		if not _check_icon(impact_name):
			quit(1)
			return
	for projectile_name in PROJECTILES:
		if not _check_icon(projectile_name):
			quit(1)
			return
	if not _check_ground_candidate():
		quit(1)
		return
	if not _check_active_ground():
		quit(1)
		return
	for reward_name in ["chest_closed", "xp_orb"]:
		if not _check_reward(reward_name):
			quit(1)
			return
	if not _check_title_skyline():
		quit(1)
		return
	if not _check_player_animation_sheets():
		quit(1)
		return
	var impact_atlas := load("res://assets/sprites/weapon_impacts_pixel.png") as Texture2D
	if impact_atlas == null or impact_atlas.get_size() != Vector2(640.0, 64.0):
		push_error("The impact atlas should contain ten horizontal 64x64 cells")
		quit(1)
		return
	print("Asset smoke passed: weapons, evolutions, relics, UI, roster, VFX, projectiles, environment, rewards and skyline")
	quit()

func _check_icon(asset_name: String) -> bool:
	var is_roster := ROSTER.has(asset_name)
	var is_vfx := IMPACTS.has(asset_name)
	var is_projectile := PROJECTILES.has(asset_name)
	var is_ui_icon := not is_roster and not is_vfx and not is_projectile and not asset_name.begins_with("weapon_") and not asset_name.begins_with("evolution_") and not asset_name.begins_with("relic_")
	var png_path := "res://assets/icons/catalog/%s.png" % asset_name if is_ui_icon else "res://assets/sprites/roster/%s.png" % asset_name if is_roster else "res://assets/sprites/vfx/%s.png" % asset_name if is_vfx else "res://assets/sprites/projectiles/%s.png" % asset_name if is_projectile else "res://assets/sprites/catalog/%s.png" % asset_name
	var source_family := "ui" if is_ui_icon else "roster" if is_roster else "vfx" if is_vfx else "projectiles" if is_projectile else "relics" if asset_name.begins_with("relic_") else "weapons"
	var source_folder := source_family if is_roster or is_vfx or is_projectile else "catalog_" + source_family
	var ase_path := "res://assets/source/%s/%s.aseprite" % [source_folder, asset_name]
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing PNG or Aseprite source for %s" % asset_name)
		return false
	var image := (load(png_path) as Texture2D).get_image()
	var expected_size := Vector2i(96, 96) if asset_name.begins_with("boss_") else Vector2i(64, 64) if is_vfx else Vector2i(16, 16) if is_projectile else Vector2i(24, 24) if is_roster else Vector2i(32, 32)
	if image.get_size() != expected_size:
		push_error("Catalog icon has unexpected dimensions: %s" % asset_name)
		return false
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0:
				colors[pixel.to_html(false)] = true
	if colors.size() > 16:
		push_error("Catalog icon exceeds the palette cap: %s (%d colors)" % [asset_name, colors.size()])
		return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != expected_size.x or source.get_16() != expected_size.y:
		push_error("Invalid editable Aseprite source for %s" % asset_name)
		return false
	return true

func _check_ground_candidate() -> bool:
	var png_path := "res://assets/sprites/environment/ground_moss_stone_candidate.png"
	var ase_path := "res://assets/source/environment/ground_moss_stone_candidate.aseprite"
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing PNG or Aseprite source for the ground candidate")
		return false
	var image := (load(png_path) as Texture2D).get_image()
	if image.get_size() != Vector2i(256, 256):
		push_error("The ground candidate should be a 256x256 texture composed of 16x16 pixel cells")
		return false
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			colors[image.get_pixel(x, y).to_html(false)] = true
	if colors.size() > 32:
		push_error("The ground candidate should use only the validated 32-color master palette")
		return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != 256 or source.get_16() != 256:
		push_error("Invalid editable Aseprite source for the ground candidate")
		return false
	var ruins_png := "res://assets/sprites/environment/survival_ruins_pixel.png"
	var ruins_ase := "res://assets/source/environment/survival_ruins_pixel.aseprite"
	if not FileAccess.file_exists(ruins_png) or not FileAccess.file_exists(ruins_ase):
		push_error("Missing PNG or Aseprite source for Survival ruins")
		return false
	var ruins := (load(ruins_png) as Texture2D).get_image()
	if ruins.get_size() != Vector2i(1536, 1536):
		push_error("Survival ruins should match their 1536x1536 world overlay")
		return false
	var ruins_source := FileAccess.open(ruins_ase, FileAccess.READ)
	if ruins_source == null or ruins_source.get_32() != ruins_source.get_length() or ruins_source.get_16() != 0xA5E0 or ruins_source.get_16() != 1 or ruins_source.get_16() != 1536 or ruins_source.get_16() != 1536:
		push_error("Invalid editable Aseprite source for Survival ruins")
		return false
	return true

func _check_active_ground() -> bool:
	const png_path := "res://assets/sprites/environment/survival_ground_tile.png"
	const ase_path := "res://assets/source/environment/survival_ground_tile.aseprite"
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing active 16x16 ground tile PNG or editable source")
		return false
	var image := (load(png_path) as Texture2D).get_image()
	if image.get_size() != Vector2i(16, 16):
		push_error("Active Survival ground tile must be 16x16")
		return false
	var allowed_colors := {"10152b": true, "1b2340": true, "293354": true}
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color_hex := image.get_pixel(x, y).to_html(false)
			if not allowed_colors.has(color_hex):
				push_error("Active Survival ground contains a color outside its Art Bible palette: %s" % color_hex)
				return false
			colors[color_hex] = true
	if colors.size() > 3:
		push_error("Active Survival ground should stay restrained to three low-contrast palette colors")
		return false
	for coordinate in range(16):
		if image.get_pixel(0, coordinate) != image.get_pixel(15, coordinate) or image.get_pixel(coordinate, 0) != image.get_pixel(coordinate, 15):
			push_error("Active Survival ground must tile seamlessly on both axes")
			return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != 16 or source.get_16() != 16:
		push_error("Invalid editable Aseprite source for active Survival ground")
		return false
	if not FileAccess.get_file_as_string("res://scripts/survival_session.gd").contains(png_path):
		push_error("Survival session should use the active pixel-art ground")
		return false
	return true

func _check_reward(reward_name: String) -> bool:
	var expected_size := 16 if reward_name == "xp_orb" else 32
	var png_path := "res://assets/sprites/rewards/%s.png" % reward_name
	var ase_path := "res://assets/source/rewards/%s.aseprite" % reward_name
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing PNG or Aseprite source for %s" % reward_name)
		return false
	var image := (load(png_path) as Texture2D).get_image()
	if image.get_size() != Vector2i(expected_size, expected_size):
		push_error("Unexpected dimensions for %s" % reward_name)
		return false
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0:
				colors[pixel.to_html(false)] = true
	if colors.size() > 16:
		push_error("%s exceeds the 16-color sprite palette cap" % reward_name)
		return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != expected_size or source.get_16() != expected_size:
		push_error("Invalid editable Aseprite source for %s" % reward_name)
		return false
	return true

func _check_title_skyline() -> bool:
	var png_path := "res://assets/backgrounds/title_skyline.png"
	var ase_path := "res://assets/source/backgrounds/title_skyline.aseprite"
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing title skyline PNG or Aseprite source")
		return false
	var image := (load(png_path) as Texture2D).get_image()
	if image.get_size() != Vector2i(640, 360):
		push_error("Title skyline should remain at the validated 640x360 size")
		return false
	var colors := {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			colors[image.get_pixel(x, y).to_html(false)] = true
	if colors.size() > 32:
		push_error("Title skyline should use the 32-color master palette")
		return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != 640 or source.get_16() != 360:
		push_error("Invalid editable Aseprite source for the title skyline")
		return false
	return true

func _check_player_animation_sheets() -> bool:
	var allowed_colors := {
		"080b18": true, "10152b": true, "1b2340": true, "293354": true,
		"37314f": true, "59476f": true, "075a80": true, "087fb2": true,
		"0eb8d4": true, "37e8f5": true, "7623a8": true, "826999": true,
		"ad91bb": true, "e13acb": true, "ffd447": true, "fff19a": true,
	}
	for animation in ["idle", "walk"]:
		var png_path := "res://assets/sprites/player_%s.png" % animation
		var ase_path := "res://assets/source/pilot/player_%s.aseprite" % animation
		if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
			push_error("Missing player %s sprite sheet or Aseprite source" % animation)
			return false
		var image := (load(png_path) as Texture2D).get_image()
		if image.get_size() != Vector2i(128, 128):
			push_error("Player %s sheet must be 4x4 frames of 32x32 pixels" % animation)
			return false
		for row in range(4):
			for column in range(4):
				var frame_colors := {}
				for y in range(row * 32, (row + 1) * 32):
					for x in range(column * 32, (column + 1) * 32):
						var pixel := image.get_pixel(x, y)
						if pixel.a == 0.0:
							continue
						var color_hex := pixel.to_html(false)
						frame_colors[color_hex] = true
						if not allowed_colors.has(color_hex):
							push_error("Player %s contains a color outside the Art Bible palette: %s" % [animation, color_hex])
							return false
				if frame_colors.is_empty() or frame_colors.size() > 16:
					push_error("Each player %s frame must be visible and use at most 16 colors" % animation)
					return false
		var source := FileAccess.open(ase_path, FileAccess.READ)
		if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != 128 or source.get_16() != 128:
			push_error("Invalid editable Aseprite source for player %s" % animation)
			return false
	var controller := FileAccess.get_file_as_string("res://scripts/player_controller.gd")
	if not controller.contains("player_idle.png") or not controller.contains("player_walk.png"):
		push_error("Player controller should use both Art Bible animation sheets")
		return false
	return true
