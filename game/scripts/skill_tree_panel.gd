extends CenterContainer

signal close_requested
signal unlock_requested(node_id: String)
signal respec_requested

class GraphLayer extends Control:
	var edges: Array[Dictionary] = []
	var lanes: Array[Dictionary] = []

	func _draw() -> void:
		for lane in lanes:
			var y := float(lane["y"])
			var lane_color: Color = lane["color"]
			draw_line(Vector2(0, y), Vector2(size.x, y), lane_color.darkened(0.72), 1.0)
		for edge in edges:
			var start: Vector2 = edge["start"]
			var finish: Vector2 = edge["finish"]
			var edge_color: Color = edge["color"]
			draw_line(start, finish, edge_color if edge["unlocked"] else edge_color.darkened(0.7), 2.0 if edge["unlocked"] else 1.0)

const LANE_ORDER := ["MAX HP", "DAMAGE", "MOVE SPEED", "CRIT CHANCE", "WEAPON UNLOCKS", "RELIC UNLOCKS"]
const LANE_COLORS := {
	"MAX HP": Color("#48E69B"), "DAMAGE": Color("#FF7181"), "MOVE SPEED": Color("#37E8F5"),
	"CRIT CHANCE": Color("#C67BFF"), "WEAPON UNLOCKS": Color("#FFD447"), "RELIC UNLOCKS": Color("#FF75E3"),
}
const CORE_STAT_KEYS := ["max_hp_pct", "damage_pct", "move_speed_pct", "critical_chance_pct"]
const CORE_STAT_NAMES := {
	"max_hp_pct": "MAX HP", "damage_pct": "DAMAGE",
	"move_speed_pct": "MOVE SPEED", "critical_chance_pct": "CRIT CHANCE",
}
const CORE_START_NODES := {
	"vitality_starter": "MAX HP", "focused_training": "DAMAGE",
	"fleet_footed": "MOVE SPEED", "steady_aim": "CRIT CHANCE",
}
const SOURCE_ICON := "res://assets/icons/catalog/skill_node.png"
const NODE_WIDTH := 72.0
const NODE_COLUMN_STEP := 74.0

@onready var _essence: Label = $Panel/Content/EssenceRow/Essence
@onready var _status: Label = $Panel/Content/Status
@onready var _graph_legend: HBoxContainer = $Panel/Content/Legend
@onready var _tree_scroll: ScrollContainer = $Panel/Content/TreeScroll
@onready var _graph: Control = $Panel/Content/TreeScroll/Graph
@onready var _selected_title: Label = $Panel/Content/Details/DetailContent/SelectedTitle
@onready var _selected_effect: Label = $Panel/Content/Details/DetailContent/SelectedEffect
@onready var _selected_requirements: Label = $Panel/Content/Details/DetailContent/SelectedRequirements
@onready var _unlock_button: Button = $Panel/Content/ActionRow/UnlockButton
@onready var _respec_button: Button = $Panel/Content/ActionRow/RespecButton
@onready var _close_button: Button = $Panel/Content/ActionRow/CloseButton

var progression_service: RefCounted
var selected_node_id := ""
var _profile: Dictionary = {}
var _node_buttons: Dictionary = {}
var _node_positions: Dictionary = {}
var _node_depths: Dictionary = {}
var _graph_layer: GraphLayer
var _profile_available := true

func _ready() -> void:
	var source_icon := get_node_or_null("Panel/Content/Details/DetailContent/SourceIcon") as TextureRect
	if source_icon != null:
		source_icon.texture = load(SOURCE_ICON) as Texture2D if ResourceLoader.exists(SOURCE_ICON) else null
	var essence_icon := get_node_or_null("Panel/Content/EssenceRow/EssenceIcon") as TextureRect
	if essence_icon != null:
		essence_icon.texture = load("res://assets/icons/catalog/resource_essence.png") as Texture2D if ResourceLoader.exists("res://assets/icons/catalog/resource_essence.png") else null
	visible = false
	_unlock_button.pressed.connect(_request_selected_unlock)
	_respec_button.pressed.connect(func() -> void: respec_requested.emit())
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_build_graph()

func present(profile: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_profile_available = progression_service != null and progression_service.has_method("skill_node_ids")
	if not _profile_available:
		present_error()
		return
	var resources: Dictionary = _profile.get("resources", {})
	var unlocked: Array = _profile.get("unlocked_skill_nodes", [])
	_essence.text = "ESSENCE %d" % int(resources.get("essence", 0))
	_respec_button.disabled = unlocked.is_empty()
	_refresh_graph()
	if selected_node_id.is_empty() or not _node_buttons.has(selected_node_id):
		selected_node_id = "vitality_starter" if _node_buttons.has("vitality_starter") else str(_node_buttons.keys()[0])
	_refresh_details()
	visible = true
	if selected_node_id == "vitality_starter":
		_tree_scroll.scroll_horizontal = 0
		_tree_scroll.scroll_vertical = 0
	(_unlock_button if not _unlock_button.disabled else _close_button).grab_focus()

func present_error() -> void:
	_profile_available = false
	_essence.text = "PROFILE UNAVAILABLE"
	_selected_title.text = "PROFILE COULD NOT BE READ"
	_selected_effect.text = "SKILL TREE ACTIONS DISABLED"
	_selected_requirements.text = ""
	_unlock_button.disabled = true
	_respec_button.disabled = true
	for button in _node_buttons.values():
		(button as Button).disabled = true
	visible = true
	_close_button.grab_focus()

func node_button_for_id(node_id: String) -> Button:
	return _node_buttons.get(node_id) as Button

func node_button_count() -> int:
	return _node_buttons.size()

func _build_graph() -> void:
	if progression_service == null or not progression_service.has_method("skill_node_ids") or \
		not progression_service.has_method("skill_node_definition"):
		return
	_graph_layer = GraphLayer.new()
	_graph_layer.name = "Connections"
	_graph_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_graph.add_child(_graph_layer)
	var ids: Array[String] = progression_service.skill_node_ids()
	for node_id in ids:
		_graph_depth(node_id, {})
	ids.sort_custom(_node_before)
	var lane_y := {}
	var visible_lanes := {}
	for index in range(LANE_ORDER.size()):
		lane_y[LANE_ORDER[index]] = 26.0 + index * 48.0
	var max_depth := 0
	for node_id in ids:
		var definition: Dictionary = progression_service.skill_node_definition(node_id)
		var lane := _lane_name(node_id, definition)
		var y := float(lane_y.get(lane, 26.0))
		var depth := int(definition.get("depth", 3))
		max_depth = maxi(max_depth, depth)
		var graph_depth := int(_node_depths[node_id])
		var position := Vector2(118.0 + (graph_depth - 1) * NODE_COLUMN_STEP, y - 13.0)
		_node_positions[node_id] = position
		var button := Button.new()
		button.name = "Node_%s" % node_id
		button.custom_minimum_size = Vector2(NODE_WIDTH, 26)
		button.position = position
		button.focus_mode = Control.FOCUS_ALL
		button.icon = load(SOURCE_ICON) as Texture2D if ResourceLoader.exists(SOURCE_ICON) else null
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width", 10)
		button.add_theme_font_size_override("font_size", 9)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(_select_node.bind(node_id))
		button.focus_entered.connect(_select_node.bind(node_id))
		_graph.add_child(button)
		_node_buttons[node_id] = button
		if not visible_lanes.has(lane):
			var lane_label := Label.new()
			lane_label.name = "Lane_%s" % lane.replace(" ", "_")
			lane_label.text = lane
			lane_label.position = Vector2(4, y - 6)
			lane_label.add_theme_font_size_override("font_size", 8)
			lane_label.add_theme_color_override("font_color", LANE_COLORS.get(lane, Color("#586381")))
			_graph.add_child(lane_label)
			visible_lanes[lane] = true
	for lane in LANE_ORDER:
		_graph_layer.lanes.append({"y": lane_y[lane], "color": LANE_COLORS[lane]})
	for node_id in ids:
		var definition: Dictionary = progression_service.skill_node_definition(node_id)
		for prerequisite in definition.get("prerequisites", []):
			var prerequisite_id := str(prerequisite)
			if not _node_positions.has(prerequisite_id):
				continue
			var from: Vector2 = _node_positions[prerequisite_id]
			var to: Vector2 = _node_positions[node_id]
			_graph_layer.edges.append({
				"start": from + Vector2(NODE_WIDTH, 13), "finish": to + Vector2(0, 13),
				"prerequisite_id": prerequisite_id,
				"color": LANE_COLORS.get(_lane_name(node_id, definition), Color("#37E8F5")),
				"unlocked": prerequisite_id in _profile.get("unlocked_skill_nodes", []),
			})
	_graph.custom_minimum_size = Vector2(190 + float(max_depth / 3) * 72.0, 26.0 + LANE_ORDER.size() * 48.0)
	_graph.custom_minimum_size.x = maxf(_graph.custom_minimum_size.x, 190.0 + float(_node_depths.values().max()) * NODE_COLUMN_STEP)

func _graph_depth(node_id: String, visiting: Dictionary) -> int:
	if _node_depths.has(node_id):
		return int(_node_depths[node_id])
	if visiting.has(node_id):
		return 1
	visiting[node_id] = true
	var definition: Dictionary = progression_service.skill_node_definition(node_id)
	var parent_depth := 0
	for prerequisite in definition.get("prerequisites", []):
		var prerequisite_id := str(prerequisite)
		if progression_service.skill_node_definition(prerequisite_id).is_empty():
			continue
		parent_depth = maxi(parent_depth, _graph_depth(prerequisite_id, visiting))
	var graph_depth := maxi(parent_depth + 1, ceili(float(definition.get("depth", 3)) / 3.0))
	visiting.erase(node_id)
	_node_depths[node_id] = graph_depth
	return graph_depth

func _node_before(left: String, right: String) -> bool:
	var left_definition: Dictionary = progression_service.skill_node_definition(left)
	var right_definition: Dictionary = progression_service.skill_node_definition(right)
	var left_depth := int(_node_depths.get(left, left_definition.get("depth", 0)))
	var right_depth := int(_node_depths.get(right, right_definition.get("depth", 0)))
	if left_depth != right_depth:
		return left_depth < right_depth
	return left < right

func _lane_name(node_id: String, definition: Dictionary) -> String:
	for stat_key in CORE_STAT_KEYS:
		if definition.has(stat_key):
			return CORE_STAT_NAMES[stat_key]
	if CORE_START_NODES.has(node_id):
		return CORE_START_NODES[node_id]
	var category := str(definition.get("category", ""))
	return "WEAPON UNLOCKS" if category == "weapon_unlocks" else "RELIC UNLOCKS" if category == "relic_unlocks" else "CORE STATS"

func _refresh_graph() -> void:
	var unlocked: Array = _profile.get("unlocked_skill_nodes", [])
	var essence := int(_profile.get("resources", {}).get("essence", 0))
	var available_count := 0
	for node_id in _node_buttons:
		var definition: Dictionary = progression_service.skill_node_definition(node_id)
		var button := _node_buttons[node_id] as Button
		var is_unlocked: bool = node_id in unlocked
		var available: bool = _prerequisites_met(definition, unlocked) and essence >= progression_service.skill_node_cost(node_id)
		if available and not is_unlocked:
			available_count += 1
		button.text = "%s %s" % ["✓" if is_unlocked else "◆" if available else "·", _short_node_label(node_id, definition)]
		var lane_color: Color = LANE_COLORS.get(_lane_name(node_id, definition), Color("#37e8f5"))
		button.self_modulate = lane_color if is_unlocked else Color("#fff19a") if available else Color("#7b87a2")
		var node_style := StyleBoxFlat.new()
		node_style.bg_color = Color("#14243A") if is_unlocked else Color("#211D31") if available else Color("#10172B")
		node_style.border_color = lane_color if is_unlocked else Color("#FFD447") if available else Color("#39486B")
		node_style.set_border_width_all(1)
		node_style.content_margin_left = 3.0
		node_style.content_margin_right = 3.0
		node_style.content_margin_top = 1.0
		node_style.content_margin_bottom = 1.0
		button.add_theme_stylebox_override("normal", node_style)
		var hover_style := node_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = lane_color.darkened(0.65)
		hover_style.border_color = lane_color
		button.add_theme_stylebox_override("hover", hover_style)
		button.disabled = not _profile_available
	_status.text = "%d / %d NODES UNLOCKED  ·  %d AVAILABLE" % [unlocked.size(), _node_buttons.size(), available_count]
	_graph_legend.tooltip_text = "Chaque couleur identifie une voie de progression. Les nœuds dorés sont sélectionnés; les couleurs vives indiquent les nœuds accessibles ou acquis."
	if _graph_layer != null:
		for edge in _graph_layer.edges:
			edge["unlocked"] = str(edge["prerequisite_id"]) in unlocked
		_graph_layer.queue_redraw()

func _short_node_label(node_id: String, definition: Dictionary) -> String:
	var lane := _lane_name(node_id, definition)
	if lane in CORE_STAT_NAMES.values():
		if CORE_START_NODES.has(node_id):
			return "%s 01" % lane.split(" ")[0]
		var suffix := node_id.get_slice("_", node_id.get_slice_count("_") - 1)
		return "%s %s" % [lane.split(" ")[0], suffix]
	var item_name := str(definition.get("unlock_name", node_id.replace("unlock_", "").replace("_", " "))).to_upper()
	return "%s %s" % ["W" if lane == "WEAPON UNLOCKS" else "R", item_name.get_slice(" ", 0)]

func _select_node(node_id: String) -> void:
	if not _node_buttons.has(node_id):
		return
	selected_node_id = node_id
	_refresh_details()

func _refresh_details() -> void:
	if not _profile_available or not _node_buttons.has(selected_node_id):
		return
	var definition: Dictionary = progression_service.skill_node_definition(selected_node_id)
	var unlocked: Array = _profile.get("unlocked_skill_nodes", [])
	var essence := int(_profile.get("resources", {}).get("essence", 0))
	var cost: int = progression_service.skill_node_cost(selected_node_id)
	var requirements: Array = definition.get("prerequisites", [])
	var available := _prerequisites_met(definition, unlocked) and essence >= cost
	_selected_title.text = str(definition.get("unlock_name", _short_node_label(selected_node_id, definition))).to_upper()
	_selected_effect.text = "%s  ·  %d ESSENCE  ·  %s" % [_effect_summary(definition), cost, "PROPOSED"]
	var prerequisite_names: PackedStringArray = []
	for prerequisite in requirements:
		var prerequisite_definition: Dictionary = progression_service.skill_node_definition(str(prerequisite))
		prerequisite_names.append(str(prerequisite_definition.get("unlock_name", str(prerequisite).replace("_", " "))).to_upper())
	var state := "UNLOCKED" if selected_node_id in unlocked else "AVAILABLE" if available else "LOCKED"
	var prerequisite_text := "REQUIRES " + ", ".join(prerequisite_names) if not prerequisite_names.is_empty() else "NO PREREQUISITES"
	_selected_requirements.text = "%s  ·  %s" % [state, prerequisite_text]
	_unlock_button.text = "UNLOCK NODE  ·  PROPOSED" if selected_node_id not in unlocked else "NODE UNLOCKED"
	_unlock_button.disabled = selected_node_id in unlocked or not available

func _effect_summary(definition: Dictionary) -> String:
	if definition.has("unlocks_weapon"):
		return "UNLOCKS WEAPON · " + str(definition.get("unlock_name", definition["unlocks_weapon"])).to_upper()
	if definition.has("unlocks_relic"):
		return "UNLOCKS RELIC · " + str(definition.get("unlock_name", definition["unlocks_relic"])).to_upper()
	if not str(definition.get("display_bonus", "")).is_empty():
		return str(definition["display_bonus"]).to_upper()
	for stat_key in CORE_STAT_KEYS:
		if definition.has(stat_key):
			var amount := float(definition[stat_key]) * 100.0
			return "+%.1f%% %s" % [amount, CORE_STAT_NAMES[stat_key]]
	return "EFFECT DETAILS UNAVAILABLE"

func _prerequisites_met(definition: Dictionary, unlocked: Array) -> bool:
	for prerequisite in definition.get("prerequisites", []):
		if prerequisite not in unlocked:
			return false
	return true

func _request_selected_unlock() -> void:
	if not selected_node_id.is_empty() and not _unlock_button.disabled:
		unlock_requested.emit(selected_node_id)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
