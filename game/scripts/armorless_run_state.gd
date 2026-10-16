extends RefCounted

const EQUIPMENT_SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const DRAFT_SIZE := 3

var _active := false
var _draft: Array[Dictionary] = []
var _equipment: Array[Dictionary] = []
var _flux := 0

func begin_run() -> void:
	_active = true
	_draft.clear()
	_equipment.clear()
	_flux = 0

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
	_equipment.append(_draft[index].duplicate(true))
	_draft.clear()
	return true

func temporary_equipment() -> Array[Dictionary]:
	return _equipment.duplicate(true)

func add_flux(amount: int) -> bool:
	if not _active or amount <= 0:
		return false
	_flux += amount
	return true

func spend_flux(amount: int) -> bool:
	if not _active or amount <= 0 or amount > _flux:
		return false
	_flux -= amount
	return true

func flux() -> int:
	return _flux

func end_run() -> void:
	_active = false
	_draft.clear()
	_equipment.clear()
	_flux = 0

func is_active() -> bool:
	return _active
