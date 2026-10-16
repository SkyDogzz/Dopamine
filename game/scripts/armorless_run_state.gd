extends RefCounted

const EQUIPMENT_SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const DRAFT_SIZE := 3
const PROPOSED_FLUX_BASE_PER_WAVE := 5
const PROPOSED_FLUX_PER_WAVE_INDEX := 2
const PROPOSED_ENHANCEMENT_RARITY_MULTIPLIERS := {
	"normal": 1.0, "magic": 1.25, "mystic": 1.5, "legendary": 2.0, "mythic": 2.5,
}
const PROPOSED_ENHANCEMENT_SUCCESS_CHANCE := 50.0
const PROPOSED_ENHANCEMENT_CRITICAL_FAILURE_CHANCE := 10.0

var _active := false
var _draft: Array[Dictionary] = []
var _equipment: Array[Dictionary] = []
var _flux := 0
var _last_flux_wave := 0
var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func begin_run() -> void:
	_active = true
	_draft.clear()
	_equipment.clear()
	_flux = 0
	_last_flux_wave = 0

func set_draft(proposals: Array[Dictionary]) -> bool:
	if not _active or not _draft.is_empty() or proposals.size() != DRAFT_SIZE:
		return false
	var instance_ids: Dictionary = {}
	for proposal in proposals:
		var instance_id := str(proposal.get("instance_id", ""))
		if instance_id.is_empty() or str(proposal.get("slot", "")) not in EQUIPMENT_SLOTS or \
			instance_ids.has(instance_id):
			return false
		instance_ids[instance_id] = true
	for proposal in proposals:
		_draft.append(proposal.duplicate(true))
	return true

func current_draft() -> Array[Dictionary]:
	return _draft.duplicate(true)

func select_draft_option(index: int) -> bool:
	if not _active or index < 0 or index >= _draft.size() or _draft.size() != DRAFT_SIZE:
		return false
	var selected: Dictionary = _draft[index].duplicate(true)
	for equipment_index in range(_equipment.size()):
		if str(_equipment[equipment_index].get("slot", "")) == str(selected.get("slot", "")):
			_equipment[equipment_index] = selected
			_draft.clear()
			return true
	_equipment.append(selected)
	_draft.clear()
	return true

func temporary_equipment() -> Array[Dictionary]:
	return _equipment.duplicate(true)

func add_flux(amount: int) -> bool:
	if not _active or amount <= 0:
		return false
	_flux += amount
	return true

func award_wave_flux(wave: int) -> int:
	if not _active or wave != _last_flux_wave + 1:
		return 0
	_last_flux_wave = wave
	var amount := PROPOSED_FLUX_BASE_PER_WAVE + PROPOSED_FLUX_PER_WAVE_INDEX * wave
	_flux += amount
	return amount

func spend_flux(amount: int) -> bool:
	if not _active or amount <= 0 or amount > _flux:
		return false
	_flux -= amount
	return true

func flux() -> int:
	return _flux

func enhance_equipment(instance_id: String, stat_id: String) -> Dictionary:
	if not _active:
		return {"ok": false, "error": "run_inactive"}
	for equipment in _equipment:
		if str(equipment.get("instance_id", "")) != instance_id:
			continue
		for line in equipment.get("stat_lines", []):
			if str(line.get("stat_id", "")) != stat_id:
				continue
			var level := int(line.get("enhancement_level", 0))
			if level >= 10:
				return {"ok": false, "error": "enhancement_max_level"}
			var cost := enhancement_cost(str(equipment.get("rarity", "")), level)
			if cost <= 0:
				return {"ok": false, "error": "invalid_rarity"}
			if _flux < cost:
				return {"ok": false, "error": "insufficient_flux", "cost": cost}
			_flux -= cost
			var success := int(line.get("fail_streak", 0)) >= 9 or \
				_rng.randf() * 100.0 < maxf(0.0, PROPOSED_ENHANCEMENT_SUCCESS_CHANCE - 3.0 * level)
			var critical_failure := false
			if success:
				line["enhancement_level"] = level + 1
				line["fail_streak"] = 0
			else:
				critical_failure = _rng.randf() * 100.0 < PROPOSED_ENHANCEMENT_CRITICAL_FAILURE_CHANCE
				if critical_failure:
					line["enhancement_level"] = maxi(0, level - 1)
				line["fail_streak"] = mini(9, int(line.get("fail_streak", 0)) + 1)
			return {"ok": true, "success": success, "critical_failure": critical_failure, "cost": cost}
		return {"ok": false, "error": "stat_line_not_found"}
	return {"ok": false, "error": "equipment_not_found"}

static func enhancement_cost(rarity: String, current_level: int) -> int:
	if not PROPOSED_ENHANCEMENT_RARITY_MULTIPLIERS.has(rarity) or current_level < 0 or current_level >= 10:
		return 0
	return ceili(5.0 * pow(1.5, current_level) * PROPOSED_ENHANCEMENT_RARITY_MULTIPLIERS[rarity])

func end_run() -> void:
	_active = false
	_draft.clear()
	_equipment.clear()
	_flux = 0
	_last_flux_wave = 0

func is_active() -> bool:
	return _active
