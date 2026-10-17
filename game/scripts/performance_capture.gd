extends Node

const SAMPLE_INTERVAL_SECONDS := 1.0

var _file: FileAccess
var _output_path := ""
var _elapsed_seconds := 0.0
var _window_started_at_msec := 0
var _frame_ms: Array[float] = []
var _physics_ms: Array[float] = []
var _draw_calls: Array[float] = []
var _primitives: Array[float] = []
var _started_at_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--profile-output="):
			_output_path = argument.trim_prefix("--profile-output=")
			break
	if _output_path.is_empty():
		set_process(false)
		return
	_open_output()


func _process(_delta: float) -> void:
	if _file == null:
		return
	var now_msec := Time.get_ticks_msec()
	_elapsed_seconds = float(now_msec - _started_at_msec) / 1000.0
	_frame_ms.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	_physics_ms.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	_draw_calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_primitives.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	if float(now_msec - _window_started_at_msec) / 1000.0 >= SAMPLE_INTERVAL_SECONDS:
		_write_sample()


func _exit_tree() -> void:
	if _file == null:
		return
	if not _frame_ms.is_empty():
		_write_sample()
	_file.close()
	_file = null


func _open_output() -> void:
	var absolute_path := _output_path
	if not absolute_path.is_absolute_path():
		absolute_path = ProjectSettings.globalize_path("res://../" + _output_path)
	var directory_path := absolute_path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(directory_path)
	if directory_error != OK:
		push_error("Could not create profiling output directory: %s" % directory_path)
		return
	_file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if _file == null:
		push_error("Could not open profiling output file: %s" % absolute_path)
		return
	_started_at_msec = Time.get_ticks_msec()
	_window_started_at_msec = _started_at_msec
	_file.store_line("elapsed_s,os,cpu,gpu,renderer,resolution,fps,frame_avg_ms,frame_p95_ms,frame_max_ms,physics_avg_ms,physics_p95_ms,draw_calls_avg,primitives_avg,video_memory_bytes,objects,nodes,scene,mode,difficulty,wave,wave_state,paused,enemies,projectiles")
	_file.flush()
	print("Performance capture writing to: %s" % absolute_path)


func _write_sample() -> void:
	if _frame_ms.is_empty():
		return
	var scene := get_tree().current_scene
	var session := _find_survival_session(scene) if scene != null else null
	var mode := ""
	var difficulty := ""
	var wave := ""
	var wave_state := ""
	var paused := ""
	var enemies := ""
	var projectiles := ""
	if session != null:
		mode = str(session.get("mode_id"))
		difficulty = str(session.get("difficulty_id"))
		var director: Variant = session.get("wave_director")
		if director != null:
			wave = str(director.get("wave"))
			wave_state = str(director.get("state"))
		paused = str(bool(session.get("_manually_paused")) or bool(session.get("_chest_open")) or bool(session.get("_starting_weapon_choice_open")))
		var entity_list: Array = session.get("_entities")
		var enemy_count := 0
		var projectile_count := 0
		for entity in entity_list:
			if not entity is Dictionary:
				continue
			var components: Dictionary = entity.get("components", {})
			if components.get("IsProjectile", false):
				projectile_count += 1
			elif components.has("EnemyType") and not components.get("IsXpOrb", false):
				enemy_count += 1
		enemies = str(enemy_count)
		projectiles = str(projectile_count)
	var resolution := DisplayServer.window_get_size()
	var row := PackedStringArray([
		"%.2f" % _elapsed_seconds,
		_csv(OS.get_name()),
		_csv(OS.get_processor_name()),
		_csv(RenderingServer.get_video_adapter_name()),
		_csv(str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))),
		_csv("%dx%d" % [resolution.x, resolution.y]),
		"%.2f" % float(Performance.get_monitor(Performance.TIME_FPS)),
		"%.3f" % _average(_frame_ms),
		"%.3f" % _percentile(_frame_ms, 0.95),
		"%.3f" % _maximum(_frame_ms),
		"%.3f" % _average(_physics_ms),
		"%.3f" % _percentile(_physics_ms, 0.95),
		"%.1f" % _average(_draw_calls),
		"%.1f" % _average(_primitives),
		str(int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))),
		str(int(Performance.get_monitor(Performance.OBJECT_COUNT))),
		str(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))),
		_csv(scene.scene_file_path if scene != null else ""),
		_csv(mode), _csv(difficulty), _csv(wave), _csv(wave_state), _csv(paused), enemies, projectiles,
	])
	_file.store_line(",".join(row))
	_file.flush()
	_window_started_at_msec = Time.get_ticks_msec()
	_frame_ms.clear()
	_physics_ms.clear()
	_draw_calls.clear()
	_primitives.clear()


func _find_survival_session(root: Node) -> Node:
	if root.get_script() != null and root.get_script().resource_path == "res://scripts/survival_session.gd":
		return root
	for child in root.get_children():
		var found := _find_survival_session(child)
		if found != null:
			return found
	return null


func _average(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size()) if not values.is_empty() else 0.0


func _maximum(values: Array[float]) -> float:
	var result := 0.0
	for value in values:
		result = maxf(result, value)
	return result


func _percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var ordered := values.duplicate()
	ordered.sort()
	var index := clampi(ceili(float(ordered.size()) * percentile) - 1, 0, ordered.size() - 1)
	return ordered[index]


func _csv(value: String) -> String:
	return '"%s"' % value.replace('"', '""')
