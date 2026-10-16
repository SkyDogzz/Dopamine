extends SceneTree

const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const PROGRESSION_SERVICE := preload("res://scripts/progression_service.gd")
const EQUIPMENT_GENERATOR := preload("res://scripts/equipment_generator.gd")
const TEST_DIRECTORY := "user://equipment_slots_smoke"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(directory)
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	var save_service = SAVE_SERVICE.new(directory)
	var progression = PROGRESSION_SERVICE.new(save_service, "0")
	var profile: Dictionary = progression.load_profile()["profile"]
	var generator = EQUIPMENT_GENERATOR.new(86420)
	var items: Array[Dictionary] = []
	for slot in EQUIPMENT_GENERATOR.SLOTS:
		var item: Dictionary = generator.generate_survival_item("slot_%s" % slot)
		item["slot"] = slot
		item["equipped"] = true
		items.append(item)
		if not _stat_lines_are_unique(item["stat_lines"]):
			_fail("An equipment item should not roll duplicate stat types")
			return
	profile["equipment_inventory"] = items
	if not save_service.save_slot("0", profile):
		_fail("Could not write the six-slot equipment fixture")
		return
	var equipped_profile: Dictionary = progression.load_profile()["profile"]
	if not _has_exactly_one_equipped_item_per_slot(equipped_profile["equipment_inventory"]):
		_fail("Permanent equipment should support one equipped item in each of the six slots")
		return

	var replacement: Dictionary = generator.generate_survival_item("slot_helmet_replacement")
	replacement["slot"] = "helmet"
	profile = equipped_profile
	profile["equipment_inventory"].append(replacement)
	if not save_service.save_slot("0", profile):
		_fail("Could not add the replacement equipment fixture")
		return
	var result: Dictionary = progression.set_equipped(replacement["instance_id"], true)
	if not result.get("ok", false):
		_fail("A new item should equip into an occupied slot")
		return
	var replaced_profile: Dictionary = progression.load_profile()["profile"]
	if not _has_exactly_one_equipped_item_per_slot(replaced_profile["equipment_inventory"]):
		_fail("Equipping a replacement should preserve one active item in every occupied slot")
		return
	var helmet_equipped := ""
	for item in replaced_profile["equipment_inventory"]:
		if item["slot"] == "helmet" and item["equipped"]:
			helmet_equipped = item["instance_id"]
	if helmet_equipped != replacement["instance_id"]:
		_fail("The replacement should take the helmet slot and unequip its previous item")
		return
	print("Permanent equipment slot smoke passed")
	quit()

func _has_exactly_one_equipped_item_per_slot(items: Array) -> bool:
	var counts := {}
	for slot in EQUIPMENT_GENERATOR.SLOTS:
		counts[slot] = 0
	for item in items:
		if item["equipped"]:
			counts[item["slot"]] = int(counts[item["slot"]]) + 1
	for slot in EQUIPMENT_GENERATOR.SLOTS:
		if int(counts[slot]) != 1:
			return false
	return true

func _stat_lines_are_unique(stat_lines: Array) -> bool:
	var seen := {}
	for line in stat_lines:
		var stat_id: String = line["stat_id"]
		if seen.has(stat_id):
			return false
		seen[stat_id] = true
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
