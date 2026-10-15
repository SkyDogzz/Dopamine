extends CenterContainer

signal close_requested
signal unlock_requested(node_id: String)
signal respec_requested

@onready var _essence: Label = $Panel/Content/Essence
@onready var _node_button: Button = $Panel/Content/VitalityButton
@onready var _focus_button: Button = $Panel/Content/FocusButton
@onready var _respec_button: Button = $Panel/Content/RespecButton
@onready var _close_button: Button = $Panel/Content/CloseButton

const NODE_ID := "vitality_starter"
var progression_service: RefCounted

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_node_button.pressed.connect(func() -> void: unlock_requested.emit(NODE_ID))
	_focus_button.pressed.connect(func() -> void: unlock_requested.emit("focused_training"))
	_respec_button.pressed.connect(func() -> void: respec_requested.emit())

func present(profile: Dictionary) -> void:
	var resources: Dictionary = profile.get("resources", {})
	var unlocked: Array = profile.get("unlocked_skill_nodes", [])
	var essence := int(resources.get("essence", 0))
	var vitality_cost: int = progression_service.skill_node_cost(NODE_ID) if progression_service != null else 50
	var focus_cost: int = progression_service.skill_node_cost("focused_training") if progression_service != null else 80
	var has_node := NODE_ID in unlocked
	var has_focus := "focused_training" in unlocked
	_essence.text = "ESSENCE %d" % essence
	_node_button.text = "VITALITY STARTER  •  +5%% MAX HP  •  %d ESSENCE  •  PROPOSED" % vitality_cost if not has_node else "VITALITY STARTER  •  UNLOCKED"
	_node_button.disabled = has_node or essence < vitality_cost
	_focus_button.text = "FOCUSED TRAINING  •  +3%% DAMAGE  •  %d ESSENCE  •  PROPOSED" % focus_cost if not has_focus else "FOCUSED TRAINING  •  UNLOCKED"
	_focus_button.disabled = has_focus or not has_node or essence < focus_cost
	_respec_button.disabled = unlocked.is_empty()
	visible = true
	_node_button.grab_focus()

func present_error() -> void:
	_essence.text = "PROFILE UNAVAILABLE"
	_node_button.disabled = true
	_focus_button.disabled = true
	_respec_button.disabled = true
	visible = true
	_close_button.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_requested.emit()
		get_viewport().set_input_as_handled()
