extends CenterContainer

signal close_requested
signal equipment_state_requested(instance_id: String, equipped: bool)
signal enhancement_requested(instance_id: String, stat_id: String, powder_tier: String)
signal unique_effect_requested(instance_id: String, effect_id: String)
signal unique_effect_reroll_requested(instance_id: String, effect_id: String)
signal dismantle_requested(instance_id: String)
signal sell_requested(instance_id: String)

@onready var _items: GridContainer = $Panel/Content/Columns/RightColumn/Scroll/Items
@onready var _empty_state: Label = $Panel/Content/Columns/RightColumn/Scroll/Items/EmptyState
@onready var _error_state: Label = $Panel/Content/Columns/RightColumn/Scroll/Items/ErrorState
@onready var _close_button: Button = $Panel/Content/CloseButton
@onready var _resources: Label = $Panel/Content/Header/Resources
@onready var _feedback: Label = $Panel/Content/Feedback
@onready var _compare_title: Label = $Panel/Content/Columns/RightColumn/Compare/Comparison/CompareTitle
@onready var _compare_body: Label = $Panel/Content/Columns/RightColumn/Compare/Comparison/CompareBody
@onready var _item_title: Label = $Panel/Content/Columns/RightColumn/ItemHeader/ItemTitle
@onready var _management_button: Button = $Panel/Content/Columns/RightColumn/ItemHeader/ManagementButton
@onready var _portrait: TextureRect = $Panel/Content/Columns/Loadout/Body/Slots/Portrait
@onready var _character_label: Label = $Panel/Content/Columns/Loadout/Body/CharacterLabel
@onready var _slots: HBoxContainer = $Panel/Content/Columns/Loadout/Body/Slots
@onready var _total_stats: GridContainer = $Panel/Content/Columns/Loadout/Body/TotalStats/StatsBody/StatsGrid

var progression_service: RefCounted

const SLOT_ICONS := {
	"helmet": "res://assets/icons/catalog/equipment_helmet.png",
	"armor": "res://assets/icons/catalog/equipment_armor.png",
	"gloves": "res://assets/icons/catalog/equipment_gloves.png",
	"boots": "res://assets/icons/catalog/equipment_boots.png",
	"amulet": "res://assets/icons/catalog/equipment_amulet.png",
	"ring": "res://assets/icons/catalog/equipment_ring.png",
}
const RARITY_ICONS := {
	"normal": "res://assets/icons/catalog/rarity_normal.png",
	"magic": "res://assets/icons/catalog/rarity_magic.png",
	"mystic": "res://assets/icons/catalog/rarity_mystic.png",
	"legendary": "res://assets/icons/catalog/rarity_legendary.png",
	"mythic": "res://assets/icons/catalog/rarity_mythic.png",
}
const RARITY_COLORS := {
	"normal": Color("#A6AEC4"),
	"magic": Color("#57DDF5"),
	"mystic": Color("#C67BFF"),
	"legendary": Color("#FFD447"),
	"mythic": Color("#FF75E3"),
}
const POWDER_TIERS := ["basic", "refined", "pure", "prismatic"]
const PROGRESSION_SERVICE_SCRIPT := preload("res://scripts/progression_service.gd")
const EQUIPMENT_GENERATOR_SCRIPT := preload("res://scripts/equipment_generator.gd")
const PLAYER_IDLE_TEXTURE_PATH := "res://assets/sprites/player_idle.png"
const SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const SLOT_NAMES := {"helmet": "HELMET", "armor": "ARMOR", "gloves": "GLOVES", "boots": "BOOTS", "amulet": "AMULET", "ring": "RING"}
const SLOT_NODE_NAMES := {"helmet": "SlotHelmet", "armor": "SlotArmor", "gloves": "SlotGloves", "boots": "SlotBoots", "amulet": "SlotAmulet", "ring": "SlotRing"}
const LOADOUT_SUMMARY_STATS := ["max_hp", "damage_pct", "attack_speed_pct", "move_speed_pct", "critical_chance_pct", "pickup_radius_pct"]
const STAT_NAMES := {
	"damage_pct": "DAMAGE", "attack_speed_pct": "ATTACK SPEED", "critical_chance_pct": "CRIT CHANCE",
	"critical_damage_pct": "CRIT DAMAGE", "max_hp": "MAX HP", "move_speed_pct": "MOVE SPEED",
	"kill_healing_pct": "KILL HEALING", "area_pct": "AREA", "cooldown_reduction_pct": "COOLDOWN",
	"xp_pct": "XP GAIN", "pickup_radius_pct": "PICKUP RADIUS", "projectile_speed_pct": "PROJECTILE SPEED",
}
const UNIQUE_EFFECTS := [
	"lightning_burst", "overflow_shield", "evolution_shockwave",
	"elite_haste", "free_first_chest_reroll", "expanded_loadout", "revive_once",
]
const DISMANTLE_POWDER := {
	"normal": "1 BASIC", "magic": "3 BASIC", "mystic": "1 REFINED",
	"legendary": "3 REFINED", "mythic": "1 PURE",
}
const SELL_ESSENCE: Dictionary = PROGRESSION_SERVICE_SCRIPT.PROPOSED_SELL_ESSENCE

var _sell_confirmation: Control
var _sell_description: Label
var _pending_sell_instance_id := ""
var _profile: Dictionary = {}
var _selected_slot := "helmet"
var _selected_instance_id := ""
var _management_mode := false
var _slot_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_close)
	_management_button.pressed.connect(_toggle_management_mode)
	for slot in SLOTS:
		var button := _slots.find_child(SLOT_NODE_NAMES[slot], true, false) as Button
		_slot_buttons[slot] = button
		button.icon = load(SLOT_ICONS[slot]) as Texture2D if ResourceLoader.exists(SLOT_ICONS[slot]) else null
		button.expand_icon = true
		button.icon_max_width = 13
		button.add_theme_font_size_override("font_size", 6)
		button.pressed.connect(func() -> void: _select_slot(slot))
	_sell_confirmation = load("res://scenes/sell_confirmation.tscn").instantiate()
	_sell_description = _sell_confirmation.get_node("Center/Panel/Content/Description")
	_sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton").pressed.connect(_cancel_sell)
	_sell_confirmation.get_node("Center/Panel/Content/Actions/SellButton").pressed.connect(_confirm_sell)
	add_child(_sell_confirmation)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _sell_confirmation.visible:
			_cancel_sell()
			get_viewport().set_input_as_handled()
			return
		_close()
		get_viewport().set_input_as_handled()

func present(profile: Dictionary) -> void:
	_clear_items()
	_error_state.visible = false
	_feedback.visible = false
	_profile = profile.duplicate(true)
	_selected_instance_id = ""
	_management_mode = false
	_selected_slot = "helmet"
	var inventory: Array = profile.get("equipment_inventory", [])
	for equipment in inventory:
		if bool(equipment.get("equipped", false)):
			_selected_slot = str(equipment.get("slot", "helmet"))
			break
	var resources: Dictionary = profile.get("resources", {})
	_resources.text = "ESSENCE %d" % int(resources.get("essence", 0))
	var player_sheet := load(PLAYER_IDLE_TEXTURE_PATH) as Texture2D if ResourceLoader.exists(PLAYER_IDLE_TEXTURE_PATH) else null
	if player_sheet != null:
		var player_frame := AtlasTexture.new()
		player_frame.atlas = player_sheet
		player_frame.region = Rect2(0, 0, 32, 32)
		_portrait.texture = player_frame
	else:
		_portrait.texture = null
	_refresh_slots()
	_rebuild_inventory(inventory, resources)
	visible = true
	(_slot_buttons[_selected_slot] as Button).grab_focus()

func present_error() -> void:
	_clear_items()
	_profile.clear()
	_empty_state.visible = false
	_error_state.visible = true
	visible = true
	_close_button.grab_focus()

func show_feedback(message: String) -> void:
	_feedback.text = message
	_feedback.visible = true

func selected_slot() -> String:
	return _selected_slot

func set_selected_slot(slot: String) -> void:
	if slot in SLOTS:
		_select_slot(slot)

func inventory_item_count() -> int:
	var count := 0
	for child in _items.get_children():
		if child is Control and child.name.begins_with("Equipment_"):
			count += 1
	return count

func _select_slot(slot: String) -> void:
	_selected_slot = slot
	_selected_instance_id = ""
	_refresh_slots()
	_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))

func _refresh_slots() -> void:
	var equipped_count := 0
	var totals: Dictionary = {}
	for stat_id in LOADOUT_SUMMARY_STATS:
		totals[stat_id] = 0.0
	for slot in SLOTS:
		var equipped: Dictionary = {}
		for equipment in _profile.get("equipment_inventory", []):
			if equipment.get("slot", "") == slot and equipment.get("equipped", false):
				equipped = equipment
				equipped_count += 1
				for line in equipment.get("stat_lines", []):
					var stat_id := str(line.get("stat_id", ""))
					if totals.has(stat_id):
						totals[stat_id] += EQUIPMENT_GENERATOR_SCRIPT.stat_value(
							stat_id, float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0))
						)
				break
		var button: Button = _slot_buttons[slot]
		var rarity := str(equipped.get("rarity", ""))
		button.text = "%s\n%s" % [SLOT_NAMES[slot], rarity.to_upper() if not rarity.is_empty() else "EMPTY"]
		button.button_pressed = slot == _selected_slot
		button.toggle_mode = true
		button.tooltip_text = str(equipped.get("instance_id", "No item equipped"))
		var accent: Color = RARITY_COLORS.get(rarity, Color("#39486B"))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#10172B")
		normal.border_color = accent if not rarity.is_empty() else Color("#39486B")
		normal.set_border_width_all(1)
		normal.content_margin_left = 3.0
		normal.content_margin_right = 3.0
		normal.content_margin_top = 2.0
		normal.content_margin_bottom = 2.0
		button.add_theme_stylebox_override("normal", normal)
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("#1A2A43")
		pressed.border_color = Color("#37E8F5") if slot == _selected_slot else accent
		button.add_theme_stylebox_override("pressed", pressed)
	_character_label.text = "LOADOUT  ·  %d / %d SLOTS FILLED" % [equipped_count, SLOTS.size()]
	for child in _total_stats.get_children():
		child.queue_free()
	for stat_id in LOADOUT_SUMMARY_STATS:
		var stat := Label.new()
		stat.text = "%s  %s" % [STAT_NAMES.get(stat_id, stat_id.to_upper()), EQUIPMENT_GENERATOR_SCRIPT.stat_label(stat_id, float(totals[stat_id]))]
		stat.add_theme_font_size_override("font_size", 7)
		stat.add_theme_color_override("font_color", Color("#37E8F5") if float(totals[stat_id]) > 0.0 else Color("#A6AEC4"))
		_total_stats.add_child(stat)

func _rebuild_inventory(inventory: Array, resources: Dictionary) -> void:
	_clear_items()
	_items.columns = 1 if _management_mode else 2
	var compatible: Array[Dictionary] = []
	for equipment in inventory:
		if str(equipment.get("slot", "")) == _selected_slot:
			compatible.append(equipment)
	_empty_state.visible = compatible.is_empty()
	_item_title.text = "%s  ·  %d ITEM%s" % [SLOT_NAMES[_selected_slot], compatible.size(), "" if compatible.size() == 1 else "S"]
	for equipment in compatible:
		_items.add_child(_create_item_row(equipment, resources))
	if compatible.is_empty():
		_compare_title.text = "BONUS PREVIEW  ·  NO CHANGE"
		_compare_body.text = "No item fits this slot."
	else:
		_update_comparison(false)
	if not _management_mode and not _selected_instance_id.is_empty():
		_update_comparison()

func _update_comparison(add_action: bool = true) -> void:
	var current: Dictionary = {}
	var candidate: Dictionary = {}
	for equipment in _profile.get("equipment_inventory", []):
		if equipment.get("slot", "") != _selected_slot:
			continue
		if equipment.get("equipped", false):
			current = equipment
		if equipment.get("instance_id", "") == _selected_instance_id:
			candidate = equipment
	var before := _equipment_totals(_profile.get("equipment_inventory", []), _selected_slot, "")
	var after := _equipment_totals(_profile.get("equipment_inventory", []), _selected_slot, _selected_instance_id)
	if _selected_instance_id.is_empty() or candidate.is_empty():
		after = before
	var lines := PackedStringArray()
	var stat_ids: Array = EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS
	for stat_id in stat_ids:
		var old_value := float(before.get(stat_id, 0.0))
		var new_value := float(after.get(stat_id, 0.0))
		if is_zero_approx(old_value) and is_zero_approx(new_value):
			continue
		var delta := new_value - old_value
		lines.append("%s  %.1f → %.1f  (%+.1f)" % [STAT_NAMES.get(stat_id, str(stat_id).to_upper()), old_value, new_value, delta])
	_compare_title.text = "BEFORE → AFTER  ·  %s" % SLOT_NAMES[_selected_slot]
	_compare_body.text = "\n".join(lines) if not lines.is_empty() else \
		("EQUIPPED ITEM SELECTED  ·  NO CHANGE" if not current.is_empty() and current.get("instance_id", "") == _selected_instance_id else "NO EQUIPPED BONUS  →  NO CHANGE")
	if not add_action:
		return
	for child in _items.get_children():
		if child is Button and (child as Button).name == "EquipAction":
			_items.remove_child(child)
			child.queue_free()
	var action := Button.new()
	action.name = "EquipAction"
	var remove_equipped: bool = not current.is_empty() and current.get("instance_id", "") == _selected_instance_id
	if remove_equipped:
		action.text = "REMOVE EQUIPPED ITEM"
		action.disabled = false
	elif candidate.is_empty():
		action.text = "SELECT AN ITEM TO EQUIP"
		action.disabled = true
	else:
		action.text = "EQUIPPED" if current.get("instance_id", "") == _selected_instance_id else "EQUIP SELECTED ITEM"
		action.disabled = current.get("instance_id", "") == _selected_instance_id
	var action_instance_id := str(current.get("instance_id", "")) if remove_equipped else _selected_instance_id
	var action_equipped: bool = not remove_equipped
	action.pressed.connect(func() -> void: equipment_state_requested.emit(action_instance_id, action_equipped))
	_items.add_child(action)

func _equipment_totals(inventory: Array, replaced_slot: String, candidate_id: String) -> Dictionary:
	var totals: Dictionary = {}
	for stat_id in EQUIPMENT_GENERATOR_SCRIPT.STAT_IDS:
		totals[stat_id] = 0.0
	for equipment in inventory:
		var active := bool(equipment.get("equipped", false))
		if str(equipment.get("slot", "")) == replaced_slot:
			active = not candidate_id.is_empty() and str(equipment.get("instance_id", "")) == candidate_id
		if not active:
			continue
		for line in equipment.get("stat_lines", []):
			var stat_id := str(line.get("stat_id", ""))
			totals[stat_id] += EQUIPMENT_GENERATOR_SCRIPT.stat_value(stat_id, float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0)))
	return totals

func _toggle_management_mode() -> void:
	_management_mode = not _management_mode
	_management_button.text = "LOADOUT" if _management_mode else "DETAILS"
	_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))

func _create_item_row(equipment: Dictionary, resources: Dictionary) -> Control:
	if not _management_mode:
		return _create_loadout_item_row(equipment)
	var row := PanelContainer.new()
	row.name = "Equipment_%s" % str(equipment.get("instance_id", "item"))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("#10172B")
	row_style.border_color = Color("#39486B")
	row_style.border_width_top = 1
	row_style.border_width_right = 1
	row_style.border_width_bottom = 1
	row_style.border_width_left = 3
	row_style.border_color = RARITY_COLORS.get(str(equipment.get("rarity", "normal")), Color("#A6AEC4"))
	row_style.content_margin_left = 6.0
	row_style.content_margin_top = 5.0
	row_style.content_margin_right = 6.0
	row_style.content_margin_bottom = 5.0
	row.add_theme_stylebox_override("panel", row_style)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	row.add_child(layout)
	var slot := str(equipment.get("slot", ""))
	var rarity := str(equipment.get("rarity", ""))
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 2)
	for badge_data in [
		["SlotIcon", SLOT_ICONS.get(slot, ""), slot.replace("_", " ").capitalize()],
		["RarityIcon", RARITY_ICONS.get(rarity, ""), rarity.capitalize()],
	]:
		var icon_path: String = badge_data[1]
		if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
			continue
		var icon := TextureRect.new()
		icon.name = badge_data[0]
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = (load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null)
		icon.tooltip_text = badge_data[2]
		badges.add_child(icon)
	layout.add_child(badges)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	layout.add_child(content)
	var title := Label.new()
	title.text = "%s  •  %s" % [rarity.to_upper(), slot.to_upper()]
	content.add_child(title)
	for line in equipment.get("stat_lines", []):
		var enhancement_row := HBoxContainer.new()
		content.add_child(enhancement_row)
		var details := Label.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.text = "%s — %s  +%d/10" % [
			str(line.get("stat_id", "")).replace("_", " ").to_upper(),
			EQUIPMENT_GENERATOR_SCRIPT.stat_label(str(line.get("stat_id", "")),
				EQUIPMENT_GENERATOR_SCRIPT.stat_value(str(line.get("stat_id", "")),
					float(line.get("roll_percentile", 0.0)), int(line.get("enhancement_level", 0)))),
			int(line.get("enhancement_level", 0)),
		]
		enhancement_row.add_child(details)
		var powder_choice := OptionButton.new()
		powder_choice.custom_minimum_size.x = 58
		for tier_index in range(POWDER_TIERS.size()):
			powder_choice.add_item(POWDER_TIERS[tier_index].to_upper())
			powder_choice.set_item_metadata(tier_index, POWDER_TIERS[tier_index])
		enhancement_row.add_child(powder_choice)
		var enhance_button := Button.new()
		enhance_button.text = "ENHANCE"
		var level := int(line.get("enhancement_level", 0))
		var update_enabled := func(_index: int = 0) -> void:
			var selected_tier: String = str(powder_choice.get_item_metadata(powder_choice.selected))
			var powder_key := "powder_%s" % selected_tier
			enhance_button.disabled = level >= 10 or progression_service == null or \
					int(resources.get(powder_key, 0)) < progression_service.enhancement_cost(rarity, level)
		powder_choice.item_selected.connect(update_enabled)
		update_enabled.call()
		enhance_button.pressed.connect(func() -> void:
			enhancement_requested.emit(
				str(equipment.get("instance_id", "")), str(line.get("stat_id", "")),
				str(powder_choice.get_item_metadata(powder_choice.selected))
			)
		)
		enhancement_row.add_child(enhance_button)
	var status := Label.new()
	status.add_theme_color_override("font_color", Color("#FFD447"))
	status.text = "PROPOSED STAT ROLLS — experimental balance"
	if equipment.get("equipped", false):
		status.text = "EQUIPPED — proposed stat rolls active"
	if equipment.get("unique_effect_id") == "pending_choice":
		status.text += "\nUnique effect choice pending"
	elif str(equipment.get("unique_effect_id", "")) != "":
		var effect_id := str(equipment["unique_effect_id"])
		var effect_status := "VALIDATED ACTIVE" if equipment.get("equipped", false) and effect_id == "revive_once" else \
				"PROPOSED ACTIVE" if equipment.get("equipped", false) and effect_id in [
			"lightning_burst", "overflow_shield", "evolution_shockwave", "elite_haste", "free_first_chest_reroll", "expanded_loadout",
		] else "NO GAMEPLAY EFFECT YET"
		status.text += "\nUNIQUE: %s — %s" % [effect_id.replace("_", " ").to_upper(), effect_status]
		if effect_id == "expanded_loadout" and equipment.get("equipped", false):
			status.text += "\nPROPOSED: +1 WEAPON +1 RELIC SLOT (MAX 6)"
		elif effect_id == "revive_once" and equipment.get("equipped", false):
			status.text += "\nONE REVIVE PER RUN IN SURVIVAL / ENDLESS"
	content.add_child(status)
	var unique_effect_id := str(equipment.get("unique_effect_id", ""))
	var reroll_cost: Dictionary = PROGRESSION_SERVICE_SCRIPT.UNIQUE_EFFECT_REROLL_COSTS.get(rarity, {})
	if unique_effect_id == "pending_choice" or (not reroll_cost.is_empty() and not unique_effect_id.is_empty()):
		var effect_row := HBoxContainer.new()
		var effect_choice := OptionButton.new()
		for effect_id in UNIQUE_EFFECTS:
			if unique_effect_id != "pending_choice" and effect_id == unique_effect_id:
				continue
			effect_choice.add_item(effect_id.replace("_", " ").to_upper())
			effect_choice.set_item_metadata(effect_choice.item_count - 1, effect_id)
		effect_row.add_child(effect_choice)
		var effect_action := Button.new()
		if unique_effect_id == "pending_choice":
			effect_action.text = "CHOOSE EFFECT"
			effect_action.pressed.connect(func() -> void:
				unique_effect_requested.emit(
					str(equipment.get("instance_id", "")),
					str(effect_choice.get_item_metadata(effect_choice.selected))
				)
			)
		else:
			var powder_tier := str(reroll_cost["powder_tier"])
			var powder_amount := int(reroll_cost["amount"])
			effect_action.text = "REROLL  •  %d %s" % [powder_amount, powder_tier.to_upper()]
			effect_action.tooltip_text = "Choose a different unique effect for %d %s Powder." % [
				powder_amount, powder_tier.capitalize(),
			]
			effect_action.disabled = int(resources.get("powder_%s" % powder_tier, 0)) < powder_amount
			effect_action.pressed.connect(func() -> void:
				unique_effect_reroll_requested.emit(
					str(equipment.get("instance_id", "")),
					str(effect_choice.get_item_metadata(effect_choice.selected))
				)
			)
		effect_row.add_child(effect_action)
		content.add_child(effect_row)
	var equip_button := Button.new()
	equip_button.name = "EquipmentStateAction"
	var is_equipped := bool(equipment.get("equipped", false))
	equip_button.text = "UNEQUIP" if is_equipped else "EQUIP"
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.add_theme_color_override("font_color", Color("#37E8F5"))
	equip_button.add_theme_color_override("font_hover_color", Color("#37E8F5"))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	content.add_child(actions)
	equip_button.pressed.connect(func() -> void:
		equipment_state_requested.emit(str(equipment.get("instance_id", "")), not is_equipped)
	)
	actions.add_child(equip_button)
	var dismantle_button := Button.new()
	var dismantle_yield: String = DISMANTLE_POWDER[rarity]
	dismantle_button.text = "DISMANTLE  •  %s" % dismantle_yield
	dismantle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dismantle_button.add_theme_color_override("font_color", Color("#FF7181"))
	dismantle_button.add_theme_color_override("font_hover_color", Color("#FF7181"))
	dismantle_button.tooltip_text = "Proposed prototype dismantle yield: %s POWDER; economy remains open for calibration." % dismantle_yield
	dismantle_button.pressed.connect(func() -> void:
		dismantle_requested.emit(str(equipment.get("instance_id", "")))
	)
	actions.add_child(dismantle_button)
	var sell_value: int = SELL_ESSENCE[rarity]
	var sell_button := Button.new()
	sell_button.text = "SELL  •  %d ESSENCE" % sell_value
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.add_theme_color_override("font_color", Color("#FFD447"))
	sell_button.add_theme_color_override("font_hover_color", Color("#FFD447"))
	sell_button.tooltip_text = "Proposed sale value; selling removes this equipment and does not refund its enhancements."
	sell_button.pressed.connect(func() -> void:
		_pending_sell_instance_id = str(equipment.get("instance_id", ""))
		_sell_description.text = "SELL THIS %s ITEM FOR %d ESSENCE?\nTHIS CANNOT BE UNDONE." % [rarity.to_upper(), sell_value]
		_sell_confirmation.visible = true
		_sell_confirmation.get_node("Center/Panel/Content/Actions/CancelButton").grab_focus()
	)
	content.add_child(sell_button)
	return row

func _create_loadout_item_row(equipment: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Equipment_%s" % str(equipment.get("instance_id", "item"))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10172B")
	style.border_color = RARITY_COLORS.get(str(equipment.get("rarity", "normal")), Color("#A6AEC4"))
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.bg_color = Color("#17223A") if str(equipment.get("instance_id", "")) == _selected_instance_id else Color("#10172B")
	style.content_margin_left = 5.0
	style.content_margin_top = 4.0
	style.content_margin_right = 5.0
	style.content_margin_bottom = 4.0
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size = Vector2(0, 58)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	row.add_child(content)
	var line := HBoxContainer.new()
	line.name = "ItemRow"
	line.add_theme_constant_override("separation", 3)
	content.add_child(line)
	var rarity := str(equipment.get("rarity", "normal"))
	var rarity_icon_path: String = RARITY_ICONS.get(rarity, "")
	if not rarity_icon_path.is_empty() and ResourceLoader.exists(rarity_icon_path):
		var rarity_icon := TextureRect.new()
		rarity_icon.custom_minimum_size = Vector2(16, 16)
		rarity_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rarity_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rarity_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rarity_icon.texture = load(rarity_icon_path) as Texture2D
		line.add_child(rarity_icon)
	var summary := Label.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.text = "%s%s\n%s" % [rarity.to_upper(), "  ·  EQUIPPED" if equipment.get("equipped", false) else "", SLOT_NAMES[_selected_slot]]
	summary.add_theme_font_size_override("font_size", 7)
	line.add_child(summary)
	var preview := Button.new()
	preview.name = "Preview"
	preview.text = "VIEW" if str(equipment.get("instance_id", "")) != _selected_instance_id else "SELECTED"
	preview.focus_mode = Control.FOCUS_ALL
	preview.add_theme_font_size_override("font_size", 7)
	preview.pressed.connect(func() -> void:
		_selected_instance_id = str(equipment.get("instance_id", ""))
		_update_comparison()
		_rebuild_inventory(_profile.get("equipment_inventory", []), _profile.get("resources", {}))
	)
	line.add_child(preview)
	var stats := PackedStringArray()
	for stat_line in equipment.get("stat_lines", []):
		var stat_id := str(stat_line.get("stat_id", ""))
		var value := EQUIPMENT_GENERATOR_SCRIPT.stat_value(
			stat_id, float(stat_line.get("roll_percentile", 0.0)), int(stat_line.get("enhancement_level", 0))
		)
		stats.append("%s %s" % [STAT_NAMES.get(stat_id, stat_id.to_upper()), EQUIPMENT_GENERATOR_SCRIPT.stat_label(stat_id, value)])
	var stat_preview := Label.new()
	stat_preview.name = "StatPreview"
	stat_preview.text = "  ·  ".join(stats)
	stat_preview.add_theme_font_size_override("font_size", 7)
	stat_preview.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color("#A6AEC4")))
	stat_preview.clip_text = true
	content.add_child(stat_preview)
	return row

func _close() -> void:
	_sell_confirmation.visible = false
	_pending_sell_instance_id = ""
	visible = false
	close_requested.emit()

func _cancel_sell() -> void:
	_sell_confirmation.visible = false
	_pending_sell_instance_id = ""
	_management_button.grab_focus()

func _confirm_sell() -> void:
	if _pending_sell_instance_id.is_empty():
		return
	var instance_id := _pending_sell_instance_id
	_pending_sell_instance_id = ""
	_sell_confirmation.visible = false
	sell_requested.emit(instance_id)

func _clear_items() -> void:
	for child in _items.get_children():
		if child in [_empty_state, _error_state]:
			continue
		_items.remove_child(child)
		child.queue_free()
