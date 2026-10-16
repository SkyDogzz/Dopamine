extends Control

const SURVIVAL_TARGETING := preload("res://scripts/survival_targeting.gd")
const TARGETING_POLICIES := ["nearest", "highest_threat", "highest_health", "lowest_health", "farthest",
		"lightning_cluster", "sawblades_cluster", "meteor_centroid", "prism_cluster"]
const TARGETING_LABELS := ["NEAREST", "HIGHEST THREAT", "HIGHEST HP", "LOWEST HP", "FARTHEST",
		"LIGHTNING CLUSTER", "SAWBLADE CLUSTER", "METEOR CENTROID", "PRISM HIGH HP"]
const CLUSTER_POLICIES := ["lightning_cluster", "sawblades_cluster", "meteor_centroid", "prism_cluster"]

const COLOR_MUTED := Color("#8ea3ad")
const COLOR_CYAN := Color("#45e5ed")
const COLOR_PINK := Color("#ff5ca8")
const COLOR_AMBER := Color("#ffd166")

var simulation: Object
var _refresh_elapsed := 0.0
var _selected_index := -1
var _selected_generation := -1
var _last_combat_event_sequence := 0
var _damage_total := 0.0
var _pending_tuning_sequence := 0
var _pending_reset_sequence := 0

@onready var _view = $Shell/Content/MainColumn/SimulationView
@onready var _state_badge: PanelContainer = $Shell/Header/StateBadge
@onready var _state_label: Label = $Shell/Header/StateBadge/StateLabel
@onready var _survival_button: Button = $Shell/Header/SurvivalButton
@onready var _home_button: Button = $Shell/Header/HomeButton
@onready var _pause_button: Button = $Shell/Content/MainColumn/Toolbar/Row/PauseButton
@onready var _step_button: Button = $Shell/Content/MainColumn/Toolbar/Row/StepButton
@onready var _step_duration: SpinBox = $Shell/Content/MainColumn/Toolbar/Row/StepDuration
@onready var _speed_select: OptionButton = $Shell/Content/MainColumn/Toolbar/Row/SpeedSelect
@onready var _entity_type: OptionButton = $Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/EntityType
@onready var _count: SpinBox = $Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/TypeRow/CountSpin
@onready var _target_policy: OptionButton = $Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/PolicySelect
@onready var _target_range: SpinBox = $Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/RangeSpin
@onready var _cluster_radius: SpinBox = $Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/ClusterRadiusSpin
@onready var _target_status: Label = $Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/TargetStatus
@onready var _entity_info: RichTextLabel = $Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/EntityInfo
@onready var _log_text: RichTextLabel = $Shell/Content/SidePanel/Sections/LogPanel/LogForm/LogText
var _state_badge_style: StyleBoxFlat

func _ready() -> void:
	_state_badge_style = StyleBoxFlat.new()
	_state_badge_style.bg_color = Color("#10172B")
	_state_badge_style.border_color = COLOR_CYAN
	_state_badge_style.set_border_width_all(1)
	_state_badge_style.border_width_left = 2
	_state_badge_style.set_corner_radius_all(0)
	_state_badge_style.content_margin_left = 5.0
	_state_badge_style.content_margin_top = 2.0
	_state_badge_style.content_margin_right = 5.0
	_state_badge_style.content_margin_bottom = 2.0
	_state_badge.add_theme_stylebox_override("panel", _state_badge_style)
	_survival_button.pressed.connect(_on_survival_pressed)
	_home_button.pressed.connect(_on_home_pressed)
	_home_button.grab_focus()
	simulation = ClassDB.instantiate("CombatSimulation")
	if simulation == null:
		_state_label.text = "SIMULATION EXTENSION UNAVAILABLE"
		_set_state_accent(COLOR_PINK)
		push_error("CombatSimulation GDExtension class is unavailable")
		return

	var enemy_icons := {
		"chaser": "roster/enemy_chaser",
		"sprinter": "roster/enemy_sprinter",
		"tank": "roster/enemy_tank",
		"shooter": "roster/enemy_shooter",
		"buffer": "roster/enemy_buffer",
		"exploder": "roster/enemy_exploder",
		"shielder": "roster/enemy_shielder",
		"summoner": "roster/enemy_summoner",
		"summoned": "roster/enemy_summoned",
		"elite": "roster/elite_sprinter",
	}
	for entity_type in enemy_icons:
		var icon_file: String = enemy_icons[entity_type]
		if not icon_file.contains("."):
			icon_file += ".png"
		var texture: Texture2D = load("res://assets/sprites/%s" % icon_file)
		_entity_type.add_icon_item(texture, entity_type.to_upper())
		_entity_type.set_item_metadata(_entity_type.item_count - 1, entity_type)
	for speed in [0.25, 0.5, 1.0, 2.0, 4.0]:
		_speed_select.add_item("×%s" % speed)
		_speed_select.set_item_metadata(_speed_select.item_count - 1, speed)
	for index in TARGETING_POLICIES.size():
		_target_policy.add_item(TARGETING_LABELS[index])
		_target_policy.set_item_metadata(index, TARGETING_POLICIES[index])
	_apply_targeting_profile()

	$Shell/Content/MainColumn/Toolbar/Row/PauseButton.pressed.connect(_on_pause_pressed)
	$Shell/Content/MainColumn/Toolbar/Row/StepButton.pressed.connect(_on_step_pressed)
	$Shell/Content/MainColumn/Toolbar/Row/SpeedSelect.item_selected.connect(_on_speed_selected)
	_target_policy.item_selected.connect(_on_target_policy_selected)
	_target_range.value_changed.connect(_on_target_range_changed)
	_cluster_radius.value_changed.connect(_on_target_range_changed)
	$Shell/Content/MainColumn/Toolbar/Row/ResetButton.pressed.connect(_on_reset_pressed)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/SpawnButton.pressed.connect(_on_spawn_pressed)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton.pressed.connect(_on_despawn_pressed)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton.pressed.connect(_on_kill_all_pressed)
	$Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/ApplyTuningButton.pressed.connect(_on_apply_tuning_pressed)
	$Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/ApplyStatusButton.pressed.connect(_on_apply_status_pressed)
	_view.entity_selected.connect(_on_entity_selected)

	$Shell/Header/Title.add_theme_color_override("font_color", COLOR_CYAN)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnTitle.add_theme_color_override("font_color", COLOR_CYAN)
	$Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/TargetingTitle.add_theme_color_override("font_color", COLOR_AMBER)
	$Shell/Content/SidePanel/Sections/TargetingPanel/TargetingForm/TargetStatus.add_theme_color_override("font_color", COLOR_AMBER)
	$Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/InspectorTitle.add_theme_color_override("font_color", COLOR_CYAN)
	$Shell/Content/SidePanel/Sections/LogPanel/LogForm/LogTitle.add_theme_color_override("font_color", COLOR_CYAN)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/DespawnButton.add_theme_color_override("font_color", COLOR_AMBER)
	$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/SpawnActions/KillButton.add_theme_color_override("font_color", COLOR_PINK)
	$Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm/StatusTitle.add_theme_color_override("font_color", COLOR_CYAN)
	_step_duration.min_value = 0.001
	_count.value = 1
	_step_duration.value = 1.0 / 60.0
	_refresh()

func _on_survival_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/survival_entry.tscn")
	if error != OK:
		push_error("Could not open Survival entry scene: %s" % error_string(error))

func _on_home_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/launch_menu.tscn")
	if error != OK:
		push_error("Could not return to launch menu: %s" % error_string(error))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_home_pressed()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.1:
		_refresh_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	var state: Dictionary = simulation.snapshot()
	if _pending_reset_sequence > 0 and int(state["last_sequence"]) >= _pending_reset_sequence:
		var tuning: Dictionary = state["sandbox_overrides"]
		var tuning_grid := $Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid
		tuning_grid.get_node("MaxSpeedSpin").value = tuning["max_speed"]
		tuning_grid.get_node("SeparationRadiusSpin").value = tuning["separation_radius"]
		tuning_grid.get_node("SeparationWeightSpin").value = tuning["separation_weight"]
		tuning_grid.get_node("CellSizeSpin").value = tuning["cell_size"]
		$Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus.text = "TUNING RESET"
		$Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus.add_theme_color_override("font_color", COLOR_MUTED)
		_pending_reset_sequence = 0
	if _pending_tuning_sequence > 0 and int(state["last_sequence"]) >= _pending_tuning_sequence:
		$Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus.text = "LIVE TUNING APPLIED"
		$Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus.add_theme_color_override("font_color", COLOR_CYAN)
		_pending_tuning_sequence = 0
	var paused: bool = state["paused"]
	_state_label.text = "PAUSED  /  NO SAVE" if paused else "RUNNING  /  NO SAVE"
	_set_state_accent(COLOR_AMBER if paused else COLOR_CYAN)
	_pause_button.text = "RESUME" if paused else "PAUSE"
	_step_button.disabled = not paused
	_select_speed(float(state["speed_multiplier"]))
	_view.set_entities(state["entities"])
	_view.set_selected_entity(_selected_index, _selected_generation)
	var target_policy: String = str(_target_policy.get_item_metadata(_target_policy.selected))
	var target: Dictionary = SURVIVAL_TARGETING.preview_target(state["entities"], Vector2.ZERO,
		_target_range.value, _cluster_radius.value, target_policy)
	_view.set_target_preview(target, TARGETING_LABELS[_target_policy.selected])
	_target_status.text = "%s  ·  %s" % [TARGETING_LABELS[_target_policy.selected], "NO TARGET" if target.is_empty() else "#%d / G%d" % [target["id"].x, target["id"].y]]

	var metrics: Dictionary = state["metrics"]
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricFPS.text = "FPS  %d" % Engine.get_frames_per_second()
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricFrame.text = "FRAME  %.2f ms" % metrics["frame_time_ms"]
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricTime.text = "SIM  %.2f s" % state["simulation_time"]
	var simulation_time := float(state["simulation_time"])
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricEntities.text = "ENTITIES  %d" % metrics["entity_count"]
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricProjectiles.text = "PROJECTILES  %d" % metrics["projectile_count"]
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricCollisions.text = "COLLISIONS  %d" % metrics["collision_count"]
	var visible_logs: Array = Array(state["logs"])
	var latest_event_sequence := _last_combat_event_sequence
	for event in state["events"]:
		var event_sequence: int = event["sequence"]
		if event_sequence <= _last_combat_event_sequence:
			continue
		latest_event_sequence = event_sequence
		if event["type"] == "damage":
			var target_type := str(event.get("target_type", ""))
			Sfx.play("hit_heavy" if target_type in ["mid_boss", "final_boss"] else "hit_light")
			_damage_total += float(event["amount"])
			visible_logs.append("DAMAGE  %d → %d  %.1f HP left" % [event["source"]["index"], event["target"]["index"], event["remaining_health"]])
		elif event["type"] == "death":
			var target_type := str(event.get("target_type", ""))
			Sfx.play("boss_defeat" if target_type in ["mid_boss", "final_boss"] else "enemy_kill")
			var heal_preview: float = simulation.kill_heal_amount(float(event["threat_level"]))
			visible_logs.append("DEATH  entity %d  THREAT %.1f  HEAL PREVIEW +%.1f HP" % [event["target"]["index"], event["threat_level"], heal_preview])
		elif event["type"] == "xp_collected":
			Sfx.play("xp_pickup")
			visible_logs.append("XP  +%.1f collected" % event["amount"])
	if latest_event_sequence > _last_combat_event_sequence:
		_last_combat_event_sequence = latest_event_sequence
		simulation.acknowledge_events(latest_event_sequence)
	$Shell/Content/MainColumn/Metrics/MetricRow/MetricDPS.text = "AVG DPS  %.1f" % (_damage_total / simulation_time if simulation_time > 0.0 else 0.0)
	_log_text.text = "\n".join(visible_logs)
	_refresh_inspector(state["entities"])

func _select_speed(speed: float) -> void:
	for index in range(_speed_select.item_count):
		if is_equal_approx(float(_speed_select.get_item_metadata(index)), speed):
			if _speed_select.selected != index:
				_speed_select.select(index)
			return

func _refresh_inspector(entities: Array) -> void:
	for entity in entities:
		var id: Dictionary = entity["id"]
		if id["index"] == _selected_index and id["generation"] == _selected_generation:
			var components: Dictionary = entity["components"]
			var transform: Dictionary = components["Transform2D"]
			var velocity: Dictionary = components["Velocity2D"]
			var health: Dictionary = components["Health"]
			var speed := Vector2(velocity["x"], velocity["y"]).length()
			var status_text := "NONE"
			var affix_text: String = str(components.get("Affix", "NONE"))
			if components.has("DamageOverTime"):
				var status: Dictionary = components["DamageOverTime"]
				status_text = "%.1f / %.1fs  (%.1fs left)" % [status["damage_per_tick"], status["interval_seconds"], status["remaining_seconds"]]
			_entity_info.text = "[b]ENTITY %04d / G%03d[/b]\n[b]TYPE[/b]  %s\n[b]AFFIX[/b]  %s\n[b]POSITION[/b]  (%.1f, %.1f)\n[b]VELOCITY[/b]  (%.1f, %.1f)  /  SPEED %.1f\n[b]HEALTH[/b]  %.1f / %.1f\n[b]DAMAGE OVER TIME[/b]  %s" % [
				_selected_index, _selected_generation, components["EnemyType"], affix_text,
				transform["x"], transform["y"], velocity["x"], velocity["y"], speed, health["current"], health["maximum"], status_text
			]
			return
	_selected_index = -1
	_selected_generation = -1
	_entity_info.text = "Select an entity in the simulation view."

func _on_pause_pressed() -> void:
	var state: Dictionary = simulation.snapshot()
	if state["paused"]:
		simulation.resume()
	else:
		simulation.pause()
	Sfx.play("ui_pause")

func _on_step_pressed() -> void:
	if simulation.step(_step_duration.value) == 0:
		_state_label.text = "STEP REJECTED"
		_set_state_accent(COLOR_PINK)

func _on_speed_selected(index: int) -> void:
	simulation.set_speed(float(_speed_select.get_item_metadata(index)))

func _on_target_policy_selected(_index: int) -> void:
	_apply_targeting_profile()
	_refresh()

func _on_target_range_changed(_value: float) -> void:
	_refresh()

func _apply_targeting_profile() -> void:
	var policy: String = str(_target_policy.get_item_metadata(_target_policy.selected))
	var defaults: Dictionary = SURVIVAL_TARGETING.preview_defaults(policy)
	_target_range.value = defaults["range"]
	_cluster_radius.value = defaults["cluster_radius"]
	_cluster_radius.visible = policy in CLUSTER_POLICIES

func _on_reset_pressed() -> void:
	var state: Dictionary = simulation.snapshot()
	for event in state["events"]:
		_last_combat_event_sequence = maxi(_last_combat_event_sequence, int(event["sequence"]))
	if _last_combat_event_sequence > 0:
		simulation.acknowledge_events(_last_combat_event_sequence)
	_damage_total = 0.0
	_selected_index = -1
	_selected_generation = -1
	_pending_tuning_sequence = 0
	_pending_reset_sequence = simulation.reset()
	var tuning_status: Label = $Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus
	if _pending_reset_sequence == 0:
		tuning_status.text = "RESET REJECTED"
		tuning_status.add_theme_color_override("font_color", COLOR_PINK)
	else:
		tuning_status.text = "RESET QUEUED"
		tuning_status.add_theme_color_override("font_color", COLOR_AMBER)

func _on_spawn_pressed() -> void:
	var row := _entity_type.selected
	var entity_type: String = _entity_type.get_item_metadata(row)
	var position := Vector2(
		$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/PositionRow/XSpin.value,
		$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/PositionRow/YSpin.value
	)
	var velocity := Vector2(
		$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityRow/VelocityXSpin.value,
		$Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/VelocityRow/VelocityYSpin.value
	)
	var hp: float = $Shell/Content/SidePanel/Sections/SpawnPanel/SpawnForm/HealthRow/HealthSpin.value
	if simulation.spawn(entity_type, int(_count.value), position, hp, velocity) == 0:
		Sfx.play("ui_error")
		_state_label.text = "SPAWN REJECTED"
		_set_state_accent(COLOR_PINK)

func _on_kill_all_pressed() -> void:
	simulation.kill_all()
	_selected_index = -1
	_selected_generation = -1

func _on_despawn_pressed() -> void:
	if _selected_index < 0 or _selected_generation <= 0:
		return
	simulation.despawn(_selected_index, _selected_generation)
	_selected_index = -1
	_selected_generation = -1

func _on_entity_selected(index: int, generation: int) -> void:
	_selected_index = index
	_selected_generation = generation

func _on_apply_status_pressed() -> void:
	if _selected_index < 0 or _selected_generation <= 0:
		return
	var form := $Shell/Content/SidePanel/Sections/InspectorPanel/InspectorForm
	if simulation.apply_damage_over_time(_selected_index, _selected_generation,
			form.get_node("StatusDamageSpin").value, form.get_node("StatusIntervalSpin").value,
			form.get_node("StatusDurationSpin").value) == 0:
		_state_label.text = "STATUS REJECTED"
		_set_state_accent(COLOR_PINK)
	_refresh()

func _on_apply_tuning_pressed() -> void:
	var form := $Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningGrid
	var overrides := {
		"max_speed": form.get_node("MaxSpeedSpin").value,
		"separation_radius": form.get_node("SeparationRadiusSpin").value,
		"separation_weight": form.get_node("SeparationWeightSpin").value,
		"cell_size": form.get_node("CellSizeSpin").value,
	}
	var sequence: int = simulation.apply_sandbox_overrides(overrides)
	var status: Label = $Shell/Content/SidePanel/Sections/TuningPanel/TuningForm/TuningStatus
	if sequence == 0:
		status.text = "TUNING REJECTED — PREVIOUS VALUES KEPT"
		status.add_theme_color_override("font_color", COLOR_PINK)
		return
	_pending_tuning_sequence = sequence
	status.text = "TUNING QUEUED — TARGET (0, 0)"
	status.add_theme_color_override("font_color", COLOR_AMBER)

func _set_state_accent(color: Color) -> void:
	_state_label.add_theme_color_override("font_color", color)
	_state_badge_style.border_color = color
