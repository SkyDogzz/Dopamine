extends PanelContainer

signal restart_requested
signal quit_requested

@onready var _title: Label = $Content/Title
@onready var _summary: Label = $Content/Summary
@onready var _rewards: Label = $Content/Rewards
@onready var _equipment: Label = $Content/Equipment
@onready var _achievement: Label = $Content/Achievement
@onready var _restart_button: Button = $Content/RestartButton

const RESOURCE_ICONS := [
	"res://assets/icons/catalog/resource_essence.png",
	"res://assets/icons/catalog/resource_powder.png",
]

func _ready() -> void:
	$Content/RestartButton.pressed.connect(_on_restart_pressed)
	$Content/QuitButton.pressed.connect(_on_quit_pressed)
	visible = false

func show_result(victory: bool, wave_number: int, active_seconds: float, kills: int, reward: Dictionary = {}) -> void:
	for row_name in ["RewardIcons", "EquipmentIcon"]:
		var row := $Content.get_node_or_null(row_name)
		if row != null:
			$Content.remove_child(row)
			row.queue_free()
	_rewards.text = ""
	_equipment.text = ""
	_achievement.text = ""
	_title.text = "VICTORY" if victory else "RUN OVER"
	_title.add_theme_color_override("font_color", Color("#66f2bd") if victory else Color("#ff658a"))
	var total_seconds := int(floor(active_seconds))
	_summary.text = "WAVE %02d  •  %02d:%02d  •  %d KILLS" % [wave_number, total_seconds / 60, total_seconds % 60, kills]
	if reward.is_empty():
		_rewards.text = "RUN SANS SAUVEGARDE"
		_equipment.text = ""
		_achievement.text = ""
	elif reward.get("ok", false):
		_achievement.text = "EXTERMINATOR TIER +%d  •  PROPOSED THRESHOLDS" % int(reward.get("new_achievement_tiers", 0)) if int(reward.get("new_achievement_tiers", 0)) > 0 else ""
		if reward.get("duplicate", false):
			_rewards.text = "ALREADY REWARDED"
			_equipment.text = ""
		else:
			_rewards.text = "+%d ESSENCE  •  +%d BASIC POWDER" % [reward["essence"], reward["powder_basic"]]
			_add_icon_row("RewardIcons", _rewards, RESOURCE_ICONS)
			var equipment: Dictionary = reward.get("equipment", {})
			_equipment.text = "EQUIPMENT: %s %s" % [str(equipment.get("rarity", "")).to_upper(), str(equipment.get("slot", "")).to_upper()]
			var rarity := str(equipment.get("rarity", "normal"))
			var icon_path := "res://assets/icons/catalog/rarity_%s.png" % rarity
			if not ResourceLoader.exists(icon_path):
				icon_path = "res://assets/icons/catalog/equipment_%s.png" % str(equipment.get("slot", ""))
			_add_icon_row("EquipmentIcon", _equipment, [icon_path])
			if equipment.get("unique_effect_id") == "pending_choice":
				_equipment.text += "  •  UNIQUE EFFECT CHOICE PENDING"
	else:
		_rewards.text = "PROGRESSION SAVE FAILED"
	visible = true
	_restart_button.grab_focus()

func _add_icon_row(row_name: String, anchor: Control, paths: Array) -> void:
	var content: VBoxContainer = $Content
	var old := content.get_node_or_null(row_name)
	if old != null:
		old.queue_free()
	var row := HBoxContainer.new()
	row.name = row_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = load(path)
		row.add_child(icon)
	content.add_child(row)
	content.move_child(row, anchor.get_index() + 1)

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
