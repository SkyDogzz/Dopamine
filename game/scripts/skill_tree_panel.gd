extends CenterContainer

signal close_requested
signal unlock_requested(node_id: String)
signal respec_requested

@onready var _essence: Label = $Panel/Content/EssenceRow/Essence
@onready var _node_button: Button = $Panel/Content/NodeBranch/FoundationCard/Content/VitalityButton
@onready var _focus_button: Button = $Panel/Content/NodeBranch/FollowupCard/Content/FocusButton
@onready var _node_effect: Label = $Panel/Content/NodeBranch/FoundationCard/Content/Effect
@onready var _focus_effect: Label = $Panel/Content/NodeBranch/FollowupCard/Content/Effect
@onready var _focus_kicker: Label = $Panel/Content/NodeBranch/FollowupCard/Content/Kicker
@onready var _mastery_button: Button = $Panel/Content/NodeBranch/FollowupCard/Content/MasteryButton
@onready var _mastery_effect: Label = $Panel/Content/NodeBranch/FollowupCard/Content/MasteryEffect
@onready var _mastery_kicker: Label = $Panel/Content/NodeBranch/FollowupCard/Content/MasteryKicker
@onready var _respec_button: Button = $Panel/Content/RespecButton
@onready var _close_button: Button = $Panel/Content/CloseButton

const NODE_ID := "vitality_starter"
var progression_service: RefCounted

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_node_button.pressed.connect(func() -> void: unlock_requested.emit(NODE_ID))
	_focus_button.pressed.connect(func() -> void: unlock_requested.emit("focused_training"))
	_mastery_button.pressed.connect(func() -> void: unlock_requested.emit("fleet_footed"))
	_respec_button.pressed.connect(func() -> void: respec_requested.emit())

func present(profile: Dictionary) -> void:
	var resources: Dictionary = profile.get("resources", {})
	var unlocked: Array = profile.get("unlocked_skill_nodes", [])
	var essence := int(resources.get("essence", 0))
	var vitality_cost: int = progression_service.skill_node_cost(NODE_ID) if progression_service != null else 50
	var focus_cost: int = progression_service.skill_node_cost("focused_training") if progression_service != null else 80
	var mastery_cost: int = progression_service.skill_node_cost("fleet_footed") if progression_service != null else 110
	var has_node := NODE_ID in unlocked
	var has_focus := "focused_training" in unlocked
	var has_mastery := "fleet_footed" in unlocked
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
	_respec_button.disabled = unlocked.is_empty()
	visible = true
	_node_button.grab_focus()

func present_error() -> void:
	_essence.text = "PROFILE UNAVAILABLE"
	_node_effect.text = "PROFILE COULD NOT BE READ"
	_focus_effect.text = "PROFILE COULD NOT BE READ"
	_mastery_effect.text = "PROFILE COULD NOT BE READ"
	_node_button.disabled = true
	_focus_button.disabled = true
	_mastery_button.disabled = true
	_respec_button.disabled = true
	_node_button.text = "UNAVAILABLE"
	_focus_button.text = "UNAVAILABLE"
	_mastery_button.text = "UNAVAILABLE"
	_focus_kicker.text = "FOLLOW-UP · LOCKED"
	_mastery_kicker.text = "MASTERY · LOCKED"
	visible = true
	_close_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
