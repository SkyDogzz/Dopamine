extends PanelContainer

signal restart_requested
signal quit_requested

@onready var _title: Label = $Content/Title
@onready var _summary: Label = $Content/Summary
@onready var _rewards: Label = $Content/Rewards
@onready var _equipment: Label = $Content/Equipment
@onready var _achievement: Label = $Content/Achievement
@onready var _record: Label = $Content/Record
@onready var _restart_button: Button = $Content/RestartButton

const RESOURCE_ICONS := [
	"res://assets/icons/catalog/resource_essence.png",
	"res://assets/icons/catalog/resource_powder.png",
]
const ACHIEVEMENT_ICON := "res://assets/icons/catalog/achievement_medal.png"

func _ready() -> void:
	$Content/RestartButton.pressed.connect(_on_restart_pressed)
	$Content/QuitButton.pressed.connect(_on_quit_pressed)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()

func show_result(victory: bool, wave_number: int, active_seconds: float, kills: int, reward: Dictionary = {},
		armorless_record: Dictionary = {}) -> void:
	for row_name in ["RewardIcons", "AchievementIcon", "EquipmentIcon"]:
		var row := $Content.get_node_or_null(row_name)
		if row != null:
			$Content.remove_child(row)
			row.queue_free()
	_rewards.text = ""
	_rewards.add_theme_color_override("font_color", Color("#37E8F5"))
	_equipment.text = ""
	_achievement.text = ""
	_record.text = ""
	_title.text = "VICTORY" if victory else "RUN OVER"
	var result_color := Color("#48E69B") if victory else Color("#FF7181")
	_title.add_theme_color_override("font_color", result_color)
	var result_surface := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	result_surface.border_color = result_color
	add_theme_stylebox_override("panel", result_surface)
	var total_seconds := int(floor(active_seconds))
	_summary.text = "WAVE %02d  •  %02d:%02d  •  %d KILLS" % [wave_number, total_seconds / 60, total_seconds % 60, kills]
	if not armorless_record.is_empty():
		if not armorless_record.get("ok", false):
			_record.text = "RECORD SAVE FAILED"
			_record.add_theme_color_override("font_color", Color("#FF7181"))
		else:
			var record: Dictionary = armorless_record["record"]
			var record_seconds := int(floor(float(record["survival_time_seconds"])))
			var prefix := "NEW PERSONAL BEST" if armorless_record.get("updated", false) else "PERSONAL BEST"
			_record.text = "%s  ·  WAVE %02d  ·  %02d:%02d  ·  %d KILLS" % [
				prefix, int(record["wave"]), record_seconds / 60, record_seconds % 60, int(record["kills"]),
			]
	if reward.is_empty():
		_rewards.text = "RUN SANS SAUVEGARDE"
		_equipment.text = ""
		_achievement.text = ""
	elif reward.get("ok", false):
		var exterminator_tiers := int(reward.get("new_achievement_tiers", 0))
		var total_tiers := int(reward.get("new_achievement_tier_count", exterminator_tiers))
		var achievement_summary := []
		if exterminator_tiers > 0:
			achievement_summary.append("EXTERMINATOR TIER +%d" % exterminator_tiers)
		if total_tiers > exterminator_tiers:
			achievement_summary.append("OTHER TIERS +%d" % (total_tiers - exterminator_tiers))
		_achievement.text = "  •  ".join(achievement_summary)
		if not _achievement.text.is_empty():
			_add_icon_row("AchievementIcon", _achievement, [ACHIEVEMENT_ICON])
		if reward.get("duplicate", false):
			_rewards.text = "ALREADY REWARDED"
			_equipment.text = ""
		else:
			_rewards.text = "+%d ESSENCE  •  +%d BASIC POWDER" % [reward["essence"], reward["powder_basic"]]
			_add_icon_row("RewardIcons", _rewards, RESOURCE_ICONS)
			var equipment: Dictionary = reward.get("equipment", {})
			if not equipment.is_empty():
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
		_rewards.add_theme_color_override("font_color", Color("#FF7181"))
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
		icon.custom_minimum_size = Vector2(24, 24)
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
