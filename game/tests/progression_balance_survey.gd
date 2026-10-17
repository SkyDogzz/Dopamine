extends SceneTree

const DIFFICULTY := preload("res://scripts/survival_difficulty.gd")
const PROGRESSION := preload("res://scripts/progression_service.gd")
const SAVE_SERVICE := preload("res://scripts/save_service.gd")
const ENEMY_TYPES := ["chaser", "sprinter", "tank", "shooter", "buffer", "exploder", "shielder", "summoner", "elite", "mid_boss", "final_boss"]
const TIERS := ["fresh", "mid", "full"]
const SURVEY_ROOT := "user://progression_balance_survey"
const MAX_ACTIVE_SECONDS := 720.0
const MAX_WALL_SECONDS := 180.0
const MOVEMENT_ACTIONS := ["move_right", "move_down", "move_left", "move_up"]
const MOVEMENT_VECTORS := {
	"move_right": Vector2.RIGHT,
	"move_down": Vector2.DOWN,
	"move_left": Vector2.LEFT,
	"move_up": Vector2.UP,
}

class SurveyProgression:
	extends RefCounted
	var source: RefCounted
	func _init(service: RefCounted) -> void: source = service
	func can_save_profile() -> bool: return false
	func skill_bonus(stat_id: String) -> float: return source.skill_bonus(stat_id)
	func achievement_bonus(_stat_id: String) -> float: return 0.0
	func equipment_bonuses() -> Dictionary: return {}
	func equipped_unique_effects() -> Array[String]: return []
	func unlocked_weapon_ids() -> Array[String]: return source.unlocked_weapon_ids()
	func unlocked_relic_ids() -> Array[String]: return source.unlocked_relic_ids()

class DamageMonitor:
	extends Node
	var session: Node
	var total_damage := 0.0
	var last_sequence := 0
	func _process(_delta: float) -> void:
		if session == null or session.simulation == null:
			return
		for event in session.simulation.snapshot()["events"]:
			var sequence := int(event["sequence"])
			if sequence <= last_sequence:
				continue
			last_sequence = sequence
			if str(event["type"]) == "damage" and str(event.get("target_type", "")) in ENEMY_TYPES:
				total_damage += float(event.get("amount", 0.0))

var _case_failed := false
var _pressed_movement_actions: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := _arguments()
	var selected_tier := str(args.get("tier", "all"))
	var selected_difficulty := str(args.get("difficulty", "all"))
	var movement_pattern := str(args.get("movement", "still"))
	var replicate_count: int = clampi(int(args.get("replicates", 3)), 1, 10)
	if selected_tier != "all" and selected_tier not in TIERS:
		_fail("Unknown tier: %s" % selected_tier)
		return
	if selected_difficulty != "all" and selected_difficulty not in DIFFICULTY.ORDER:
		_fail("Unknown difficulty: %s" % selected_difficulty)
		return
	if movement_pattern not in ["still", "square", "kite"]:
		_fail("Unknown movement pattern: %s" % movement_pattern)
		return

	print("tier,difficulty,movement,replicate,unlocked_nodes,hp_bonus_pct,damage_bonus_pct,speed_bonus_pct,crit_bonus_pct,active_seconds,wall_seconds,path_distance,wave,kills,level,outgoing_damage,outgoing_dps,net_hp_loss,boss_defeated,result")
	for tier in TIERS:
		if selected_tier != "all" and tier != selected_tier:
			continue
		var progression := _build_profile(tier)
		if progression == null:
			_fail("Could not create isolated %s profile" % tier)
			return
		for difficulty_id in DIFFICULTY.ORDER:
			if selected_difficulty != "all" and difficulty_id != selected_difficulty:
				continue
			for replicate in range(replicate_count):
				await _run_case(tier, difficulty_id, replicate, progression, movement_pattern)
				if _case_failed:
					return
	Engine.time_scale = 1.0
	print("Progression balance survey completed")
	quit()

func _build_profile(tier: String) -> RefCounted:
	var profile_dir := ProjectSettings.globalize_path(SURVEY_ROOT.path_join(tier))
	if DirAccess.make_dir_recursive_absolute(profile_dir) != OK:
		return null
	for file_name in DirAccess.get_files_at(profile_dir):
		DirAccess.remove_absolute(profile_dir.path_join(file_name))
	var save_service: RefCounted = SAVE_SERVICE.new(profile_dir)
	var service: RefCounted = PROGRESSION.new(save_service, "0")
	var profile_result: Dictionary = service.load_profile()
	if not profile_result.get("ok", false):
		return null
	var profile: Dictionary = profile_result["profile"]
	profile["resources"]["essence"] = 50000
	profile["highest_unlocked_difficulty"] = "chaos"
	if not save_service.save_slot("0", profile):
		return null

	var targets: Array[String] = []
	if tier == "mid":
		targets = ["vitality_starter", "focused_training", "fleet_footed", "steady_aim"]
		for prefix in ["vitality", "focused_training", "fleet_footed", "steady_aim"]:
			for rank in range(2, 12):
				targets.append("%s_%02d" % [prefix, rank])
	elif tier == "full":
		targets = service.skill_node_ids()

	var remaining := targets.duplicate()
	while not remaining.is_empty():
		var unlocked_one := false
		for node_id in remaining.duplicate():
			var definition: Dictionary = service.skill_node_definition(node_id)
			var profile_now: Dictionary = service.load_profile()["profile"]
			var prerequisites: Array = definition.get("prerequisites", [])
			if not prerequisites.all(func(prerequisite: String) -> bool:
				return prerequisite in profile_now["unlocked_skill_nodes"]):
				continue
			var result: Dictionary = service.unlock_skill_node(node_id)
			if not result.get("ok", false):
				return null
			remaining.erase(node_id)
			unlocked_one = true
		if not unlocked_one:
			return null
	return SurveyProgression.new(service)

func _run_case(tier: String, difficulty_id: String, replicate: int, progression: RefCounted, movement_pattern: String) -> void:
	seed(20261016 + DIFFICULTY.ORDER.find(difficulty_id) * 100 + replicate)
	var monitor := DamageMonitor.new()
	monitor.process_priority = -1
	root.add_child(monitor)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.process_priority = 10
	session.progression_service = progression
	session.difficulty_id = difficulty_id
	session.skip_starting_weapon_choice = true
	session.xp_collection_radius = 10000.0
	session.chest_collection_radius = 10000.0
	root.add_child(session)
	monitor.session = session
	await process_frame
	if session.simulation == null:
		_fail("Survival session failed to initialize for %s/%s" % [tier, difficulty_id])
		return
	session._auto_select_first_chest = true
	session.simulation.set_speed(4.0)
	Engine.time_scale = 4.0
	var initial_hp: float = session.player_max_hp
	var started_at := Time.get_ticks_msec()
	var previous_position: Vector2 = session.player.global_position
	var path_distance := 0.0
	var next_movement_update: float = session.player_active_time
	while not session.run_over and session.player_active_time < MAX_ACTIVE_SECONDS and \
		Time.get_ticks_msec() - started_at < MAX_WALL_SECONDS * 1000.0:
		if movement_pattern == "square":
			_set_movement_action(posmod(floori(session.player_active_time / 3.0), MOVEMENT_ACTIONS.size()))
		elif movement_pattern == "kite" and session.player_active_time >= next_movement_update:
			_set_kite_movement(session, replicate)
			next_movement_update = session.player_active_time + 0.5
		await process_frame
		var current_position: Vector2 = session.player.global_position
		path_distance += previous_position.distance_to(current_position)
		previous_position = current_position
	_clear_movement_actions()
	var elapsed_wall := float(Time.get_ticks_msec() - started_at) / 1000.0
	var active_seconds := float(session.player_active_time)
	var result := "timeout"
	if session.run_over:
		var result_title := str(session.get_node("HUD/RunResultOverlay/RunResultPanel/Content/Title").text)
		result = "victory" if result_title == "VICTORY" else "defeat" if result_title == "RUN OVER" else "unknown"
	var boss_defeated := result == "victory"
	var profile: Dictionary = progression.source.load_profile()["profile"]
	var unlocked_count: int = profile["unlocked_skill_nodes"].size()
	var hp_bonus: float = progression.skill_bonus("max_hp_pct") * 100.0
	var damage_bonus: float = progression.skill_bonus("damage_pct") * 100.0
	var speed_bonus: float = progression.skill_bonus("move_speed_pct") * 100.0
	var crit_bonus: float = progression.skill_bonus("critical_chance_pct")
	var outgoing_damage := monitor.total_damage
	var outgoing_dps := outgoing_damage / active_seconds if active_seconds > 0.0 else 0.0
	var net_hp_loss: float = initial_hp - session.player_hp
	print("%s,%s,%s,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%d,%d,%.2f,%.2f,%.2f,%s,%s" % [
		tier, difficulty_id, movement_pattern, replicate + 1, unlocked_count, hp_bonus, damage_bonus, speed_bonus, crit_bonus,
		active_seconds, elapsed_wall, path_distance, session.wave_director.wave, session.kill_count,
		session.player_level, outgoing_damage, outgoing_dps, net_hp_loss, boss_defeated, result,
	])
	if active_seconds <= 0.0 or monitor.last_sequence <= 0:
		_case_failed = true
		_fail("Survey produced no simulation time or combat events for %s/%s" % [tier, difficulty_id])
		return
	if movement_pattern == "square" and path_distance < 100.0:
		_case_failed = true
		_fail("Square movement produced only %.1f units of travel for %s/%s" % [path_distance, tier, difficulty_id])
		return
	Engine.time_scale = 1.0
	session.queue_free()
	monitor.queue_free()
	await process_frame

func _arguments() -> Dictionary:
	var result := {"tier": "all", "difficulty": "all", "movement": "still"}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--tier="):
			result["tier"] = argument.trim_prefix("--tier=")
		elif argument.begins_with("--difficulty="):
			result["difficulty"] = argument.trim_prefix("--difficulty=")
		elif argument.begins_with("--replicates="):
			result["replicates"] = argument.trim_prefix("--replicates=")
		elif argument.begins_with("--movement="):
			result["movement"] = argument.trim_prefix("--movement=")
	return result

func _set_movement_action(action_index: int) -> void:
	var action: String = MOVEMENT_ACTIONS[action_index]
	_set_movement_vector(MOVEMENT_VECTORS[action])

func _set_kite_movement(session: Node2D, replicate: int) -> void:
	var nearest_offset := Vector2.ZERO
	var nearest_distance_squared := INF
	for entity in session.simulation.snapshot()["entities"]:
		var components: Dictionary = entity["components"]
		if components.get("IsProjectile", false) or components.get("IsXpOrb", false):
			continue
		if float(components.get("Health", {}).get("current", 0.0)) <= 0.0:
			continue
		var transform: Dictionary = components.get("Transform2D", {})
		var enemy_position := Vector2(float(transform.get("x", 0.0)), float(transform.get("y", 0.0)))
		var offset: Vector2 = session.player.global_position - enemy_position
		var distance_squared: float = offset.length_squared()
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_offset = offset
	var orbit_direction := 1.0 if replicate % 2 == 0 else -1.0
	var away := nearest_offset.normalized() if nearest_distance_squared > 0.0 and nearest_distance_squared < INF else Vector2.UP
	var tangent := Vector2(-away.y, away.x) * orbit_direction
	_set_movement_vector((away * 0.8 + tangent * 0.6).normalized())

func _set_movement_vector(direction: Vector2) -> void:
	var next_actions: Array[String] = []
	if direction.x < -0.35:
		next_actions.append("move_left")
	elif direction.x > 0.35:
		next_actions.append("move_right")
	if direction.y < -0.35:
		next_actions.append("move_up")
	elif direction.y > 0.35:
		next_actions.append("move_down")
	if next_actions == _pressed_movement_actions:
		return
	_clear_movement_actions()
	_pressed_movement_actions = next_actions
	for action in _pressed_movement_actions:
		Input.action_press(action)

func _clear_movement_actions() -> void:
	for action in _pressed_movement_actions:
		Input.action_release(action)
	_pressed_movement_actions.clear()

func _fail(message: String) -> void:
	_case_failed = true
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
