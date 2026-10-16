extends SceneTree

const WEAPONS := ["lightning_conductor", "inferno_sprayer", "crimson_daggers", "minigun", "toxic_cloud", "sawblades", "meteor_staff", "prism_laser", "void_orb", "frost_nova"]
const RELICS := ["storm_core", "infernal_heart", "blood_chalice", "celestial_eye", "frozen_crown", "magnet_heart", "magnetic_coil", "overdrive_engine", "plague_mask", "prism_crystal", "singularity"]

func _initialize() -> void:
	for weapon_id in WEAPONS:
		if not _check_icon("weapon_" + weapon_id) or not _check_icon("evolution_" + weapon_id):
			quit(1)
			return
	for relic_id in RELICS:
		if not _check_icon("relic_" + relic_id):
			quit(1)
			return
	print("Catalog icon assets smoke passed: ten weapons, ten evolutions, eleven relics")
	quit()

func _check_icon(asset_name: String) -> bool:
	var png_path := "res://assets/sprites/catalog/%s.png" % asset_name
	var ase_path := "res://assets/source/catalog_%s/%s.aseprite" % ["relics" if asset_name.begins_with("relic_") else "weapons", asset_name]
	if not FileAccess.file_exists(png_path) or not FileAccess.file_exists(ase_path):
		push_error("Missing PNG or Aseprite source for %s" % asset_name)
		return false
	var image := (load(png_path) as Texture2D).get_image()
	if image.get_size() != Vector2i(32, 32):
		push_error("Catalog icon has unexpected dimensions: %s" % asset_name)
		return false
	var colors := {}
	for y in range(32):
		for x in range(32):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0:
				colors[pixel.to_html(false)] = true
	if colors.size() > 16:
		push_error("Catalog icon exceeds the palette cap: %s (%d colors)" % [asset_name, colors.size()])
		return false
	var source := FileAccess.open(ase_path, FileAccess.READ)
	if source == null or source.get_32() != source.get_length() or source.get_16() != 0xA5E0 or source.get_16() != 1 or source.get_16() != 32 or source.get_16() != 32:
		push_error("Invalid editable Aseprite source for %s" % asset_name)
		return false
	return true
