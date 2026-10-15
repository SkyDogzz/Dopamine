extends PanelContainer

signal restart_requested

@onready var _title: Label = $Content/Title
@onready var _summary: Label = $Content/Summary
@onready var _rewards: Label = $Content/Rewards
@onready var _equipment: Label = $Content/Equipment

func _ready() -> void:
	$Content/RestartButton.pressed.connect(_on_restart_pressed)
	visible = false

func show_result(victory: bool, wave_number: int, active_seconds: float, kills: int, reward: Dictionary = {}) -> void:
	_title.text = "VICTORY" if victory else "RUN OVER"
	_title.add_theme_color_override("font_color", Color("#66f2bd") if victory else Color("#ff658a"))
	var total_seconds := int(floor(active_seconds))
	_summary.text = "WAVE %02d  •  %02d:%02d  •  %d KILLS" % [wave_number, total_seconds / 60, total_seconds % 60, kills]
	if reward.is_empty():
		_rewards.text = "NO PROFILE ATTACHED"
		_equipment.text = ""
	elif reward.get("ok", false):
		if reward.get("duplicate", false):
			_rewards.text = "ALREADY REWARDED"
			_equipment.text = ""
		else:
			_rewards.text = "+%d ESSENCE  •  +%d BASIC POWDER" % [reward["essence"], reward["powder_basic"]]
			var equipment: Dictionary = reward.get("equipment", {})
			_equipment.text = "EQUIPMENT: %s %s" % [str(equipment.get("rarity", "")).to_upper(), str(equipment.get("slot", "")).to_upper()]
			if equipment.get("unique_effect_id") == "pending_choice":
				_equipment.text += "  •  UNIQUE EFFECT CHOICE PENDING"
	else:
		_rewards.text = "PROGRESSION SAVE FAILED"
		_equipment.text = ""
	visible = true

func _on_restart_pressed() -> void:
	restart_requested.emit()
