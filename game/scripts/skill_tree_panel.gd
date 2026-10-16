extends CenterContainer

signal close_requested
signal unlock_requested(node_id: String)
signal respec_requested

@onready var _essence: Label = $Panel/Content/EssenceRow/Essence
@onready var _node_button: Button = $Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/VitalityButton
@onready var _focus_button: Button = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/FocusButton
@onready var _node_effect: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FoundationCard/Content/Effect
@onready var _focus_effect: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/Effect
@onready var _focus_kicker: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/Kicker
@onready var _mastery_button: Button = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryButton
@onready var _mastery_effect: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryEffect
@onready var _mastery_kicker: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/MasteryKicker
@onready var _precision_button: Button = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionButton
@onready var _precision_effect: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionEffect
@onready var _precision_kicker: Label = $Panel/Content/NodeScroll/Rows/NodeBranch/FollowupCard/Content/PrecisionKicker
@onready var _weapon_unlock_button: Button = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/WeaponUnlockButton
@onready var _weapon_unlock_effect: Label = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/Effect
@onready var _weapon_unlock_status: Label = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockWeaponCard/Content/Prerequisite
@onready var _relic_unlock_button: Button = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/RelicUnlockButton
@onready var _relic_unlock_effect: Label = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/Effect
@onready var _relic_unlock_status: Label = $Panel/Content/NodeScroll/Rows/UnlockBranch/UnlockRelicCard/Content/Prerequisite
@onready var _additional_unlocks: VBoxContainer = $Panel/Content/NodeScroll/Rows/AdditionalUnlocks
@onready var _respec_button: Button = $Panel/Content/RespecButton
@onready var _close_button: Button = $Panel/Content/CloseButton

const NODE_ID := "vitality_starter"
var progression_service: RefCounted
var _additional_unlock_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_node_button.pressed.connect(func() -> void: unlock_requested.emit(NODE_ID))
	_focus_button.pressed.connect(func() -> void: unlock_requested.emit("focused_training"))
	_mastery_button.pressed.connect(func() -> void: unlock_requested.emit("fleet_footed"))
	_precision_button.pressed.connect(func() -> void: unlock_requested.emit("steady_aim"))
	_weapon_unlock_button.pressed.connect(func() -> void: unlock_requested.emit("unlock_crimson_daggers"))
	_relic_unlock_button.pressed.connect(func() -> void: unlock_requested.emit("unlock_blood_chalice"))
	_respec_button.pressed.connect(func() -> void: respec_requested.emit())
	_build_additional_unlock_buttons()

func present(profile: Dictionary) -> void:
	var resources: Dictionary = profile.get("resources", {})
	var unlocked: Array = profile.get("unlocked_skill_nodes", [])
	var essence := int(resources.get("essence", 0))
	var vitality_cost: int = progression_service.skill_node_cost(NODE_ID) if progression_service != null else 50
	var focus_cost: int = progression_service.skill_node_cost("focused_training") if progression_service != null else 80
	var mastery_cost: int = progression_service.skill_node_cost("fleet_footed") if progression_service != null else 110
	var precision_cost: int = progression_service.skill_node_cost("steady_aim") if progression_service != null else 140
	var weapon_unlock_cost: int = progression_service.skill_node_cost("unlock_crimson_daggers") if progression_service != null else 130
	var relic_unlock_cost: int = progression_service.skill_node_cost("unlock_blood_chalice") if progression_service != null else 160
	var has_node := NODE_ID in unlocked
	var has_focus := "focused_training" in unlocked
	var has_mastery := "fleet_footed" in unlocked
	var has_precision := "steady_aim" in unlocked
	var has_weapon_unlock := "unlock_crimson_daggers" in unlocked
	var has_relic_unlock := "unlock_blood_chalice" in unlocked
	_essence.text = "ESSENCE %d" % essence
	_node_button.text = "UNLOCKED" if has_node else "UNLOCK NODE"
	_node_effect.text = "+5%% MAX HP  •  %d ESSENCE  •  PROPOSED" % vitality_cost
	_node_button.disabled = has_node or essence < vitality_cost
	_focus_button.text = "UNLOCKED" if has_focus else "UNLOCK NODE"
	_focus_effect.text = "+3%% DAMAGE  •  %d ESSENCE  •  PROPOSED" % focus_cost
	_focus_kicker.text = "FOLLOW-UP · UNLOCKED" if has_focus else \
		"FOLLOW-UP · AVAILABLE" if has_node and essence >= focus_cost else "FOLLOW-UP · LOCKED"
	_focus_button.disabled = has_focus or not has_node or essence < focus_cost
	_mastery_button.text = "UNLOCKED" if has_mastery else "UNLOCK NODE"
	_mastery_effect.text = "+2%% MOVE SPEED  •  %d ESSENCE  •  PROPOSED" % mastery_cost
	_mastery_kicker.text = "MASTERY · UNLOCKED" if has_mastery else \
		"MASTERY · AVAILABLE" if has_focus and essence >= mastery_cost else "MASTERY · LOCKED"
	_mastery_button.disabled = has_mastery or not has_focus or essence < mastery_cost
	_precision_button.text = "UNLOCKED" if has_precision else "UNLOCK NODE"
	_precision_effect.text = "+1%% CRIT CHANCE  •  %d ESSENCE  •  PROPOSED" % precision_cost
	_precision_kicker.text = "ADVANCED · UNLOCKED" if has_precision else \
		"ADVANCED · AVAILABLE" if has_mastery and essence >= precision_cost else "ADVANCED · LOCKED"
	_precision_button.disabled = has_precision or not has_mastery or essence < precision_cost
	_weapon_unlock_effect.text = "CRIMSON DAGGERS  •  %d ESSENCE  •  PROPOSED" % weapon_unlock_cost
	_weapon_unlock_status.text = "WEAPON · UNLOCKED" if has_weapon_unlock else \
		"WEAPON · AVAILABLE" if has_node and essence >= weapon_unlock_cost else "WEAPON · REQUIRES VITALITY"
	_weapon_unlock_button.text = "UNLOCKED" if has_weapon_unlock else "UNLOCK NODE"
	_weapon_unlock_button.disabled = has_weapon_unlock or not has_node or essence < weapon_unlock_cost
	_relic_unlock_effect.text = "BLOOD CHALICE  •  %d ESSENCE  •  PROPOSED" % relic_unlock_cost
	_relic_unlock_status.text = "RELIC · UNLOCKED" if has_relic_unlock else \
		"RELIC · AVAILABLE" if has_weapon_unlock and essence >= relic_unlock_cost else "RELIC · REQUIRES DAGGERS"
	_relic_unlock_button.text = "UNLOCKED" if has_relic_unlock else "UNLOCK NODE"
	_relic_unlock_button.disabled = has_relic_unlock or not has_weapon_unlock or essence < relic_unlock_cost
	for node_id in _additional_unlock_buttons:
		var definition: Dictionary = progression_service.skill_node_definition(node_id)
		var unlocked_node: bool = node_id in unlocked
		var prerequisites: Array = definition.get("prerequisites", [])
		var ready := true
		for prerequisite in prerequisites:
			if prerequisite not in unlocked:
				ready = false
				break
		var cost: int = progression_service.skill_node_cost(node_id)
		var button: Button = _additional_unlock_buttons[node_id]
		var category_label := "WEAPON" if definition.get("category") == "weapon_unlocks" else "RELIC"
		var state_label := "UNLOCKED" if unlocked_node else "AVAILABLE" if ready and essence >= cost else "LOCKED"
		button.text = "%s · %s · %s" % [category_label, str(definition.get("unlock_name", "" )).to_upper(), state_label]
		button.tooltip_text = "%s · %d ESSENCE · PROPOSED" % [str(definition.get("unlock_name", "")), cost]
		button.disabled = unlocked_node or not ready or essence < cost
	_respec_button.disabled = unlocked.is_empty()
	visible = true
	for button in [_node_button, _focus_button, _mastery_button, _precision_button, _weapon_unlock_button, _relic_unlock_button]:
		if not button.disabled:
			button.grab_focus()
			break
	if get_viewport().gui_get_focus_owner() == null:
		for button in _additional_unlock_buttons.values():
			if not button.disabled:
				button.grab_focus()
				break

func present_error() -> void:
	_essence.text = "PROFILE UNAVAILABLE"
	_node_effect.text = "PROFILE COULD NOT BE READ"
	_focus_effect.text = "PROFILE COULD NOT BE READ"
	_mastery_effect.text = "PROFILE COULD NOT BE READ"
	_precision_effect.text = "PROFILE COULD NOT BE READ"
	_weapon_unlock_effect.text = "PROFILE COULD NOT BE READ"
	_relic_unlock_effect.text = "PROFILE COULD NOT BE READ"
	_node_button.disabled = true
	_focus_button.disabled = true
	_mastery_button.disabled = true
	_precision_button.disabled = true
	_weapon_unlock_button.disabled = true
	_relic_unlock_button.disabled = true
	for button in _additional_unlock_buttons.values():
		button.disabled = true
	_respec_button.disabled = true
	_node_button.text = "UNAVAILABLE"
	_focus_button.text = "UNAVAILABLE"
	_mastery_button.text = "UNAVAILABLE"
	_precision_button.text = "UNAVAILABLE"
	_weapon_unlock_button.text = "UNAVAILABLE"
	_relic_unlock_button.text = "UNAVAILABLE"
	_focus_kicker.text = "FOLLOW-UP · LOCKED"
	_mastery_kicker.text = "MASTERY · LOCKED"
	_precision_kicker.text = "ADVANCED · LOCKED"
	_weapon_unlock_status.text = "WEAPON · LOCKED"
	_relic_unlock_status.text = "RELIC · LOCKED"
	visible = true
	_close_button.grab_focus()

func _build_additional_unlock_buttons() -> void:
	if progression_service == null or not progression_service.has_method("skill_node_ids") or \
		not progression_service.has_method("skill_node_definition"):
		return
	for category in ["weapon_unlocks", "relic_unlocks"]:
		for node_id in progression_service.skill_node_ids(category):
			if node_id in ["unlock_crimson_daggers", "unlock_blood_chalice"]:
				continue
			var definition: Dictionary = progression_service.skill_node_definition(node_id)
			var name := str(definition.get("unlock_name", "Equipment"))
			var button := Button.new()
			button.name = node_id
			button.custom_minimum_size = Vector2(0, 22)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.text = "%s · %s · LOCKED" % ["WEAPON" if category == "weapon_unlocks" else "RELIC", name.to_upper()]
			button.focus_mode = Control.FOCUS_ALL
			button.pressed.connect(_emit_unlock_requested.bind(node_id))
			button.focus_entered.connect(_scroll_to_unlock_button.bind(button))
			_additional_unlocks.add_child(button)
			_additional_unlock_buttons[node_id] = button

func _emit_unlock_requested(node_id: String) -> void:
	unlock_requested.emit(node_id)

func _scroll_to_unlock_button(button: Control) -> void:
	$Panel/Content/NodeScroll.ensure_control_visible(button)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
