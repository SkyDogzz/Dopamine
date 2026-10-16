extends RefCounted

var preset_service: RefCounted
var active_preset: Dictionary = {}
var simulation: Object
var seed := 0
var progression_service: RefCounted
var normal_save_service: RefCounted

func _init(service: RefCounted = null) -> void:
	preset_service = service if service != null else load("res://scripts/sandbox_preset_service.gd").new()

func start(preset: Variant) -> Dictionary:
	var checked: Dictionary = preset_service.validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	var candidate = ClassDB.instantiate("CombatSimulation")
	if candidate == null:
		return {"ok": false, "error": "simulation_unavailable"}
	_clear_simulation()
	simulation = candidate
	active_preset = checked["preset"]
	seed = int(active_preset["seed"])
	return {"ok": true, "preset": active_preset.duplicate(true)}

func apply_preset(preset: Variant) -> Dictionary:
	var checked: Dictionary = preset_service.validate_preset(preset)
	if not checked.get("ok", false):
		return checked
	if simulation == null:
		return start(checked["preset"])
	var state: Dictionary = simulation.snapshot()
	if not bool(state.get("paused", false)):
		return {"ok": false, "error": "pause_required"}
	var reset_sequence: int = simulation.reset()
	var deadline := Time.get_ticks_msec() + 1000
	while int(simulation.snapshot().get("last_sequence", 0)) < reset_sequence and Time.get_ticks_msec() < deadline:
		await Engine.get_main_loop().process_frame
	if int(simulation.snapshot().get("last_sequence", 0)) < reset_sequence:
		return {"ok": false, "error": "reset_timeout"}
	active_preset = checked["preset"]
	seed = int(active_preset["seed"])
	return {"ok": true, "preset": active_preset.duplicate(true)}

func stop() -> void:
	_clear_simulation()
	active_preset.clear()
	seed = 0

func _clear_simulation() -> void:
	if simulation != null:
		simulation = null
