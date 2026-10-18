extends Control

signal close_requested

const TIER_NAMES := ["BRONZE", "ARGENT", "OR", "DIAMANT"]
const STAT_NAMES := {
	"damage_pct": "DÉGÂTS", "max_hp_pct": "PV MAX", "move_speed_pct": "VITESSE",
	"attack_speed_pct": "VITESSE D’ATTAQUE", "critical_chance_pct": "CHANCE CRITIQUE",
}

@onready var _title: Label = $Center/Panel/Content/Header/Title
@onready var _intro: Label = $Center/Panel/Content/Intro
@onready var _category: OptionButton = $Center/Panel/Content/Category
@onready var _entries: VBoxContainer = $Center/Panel/Content/Body/Entries
@onready var _close_button: Button = $Center/Panel/Content/Header/CloseButton

var _catalog: Array[Dictionary] = []
var _profile: Dictionary = {}
var _categories: Array[String] = []

func _ready() -> void:
	visible = false
	_close_button.pressed.connect(func() -> void: close_requested.emit())
	_category.item_selected.connect(_show_category)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	close_requested.emit()
	if get_viewport() != null:
		get_viewport().set_input_as_handled()

func present(catalog: Array[Dictionary], profile: Dictionary) -> void:
	_catalog = catalog.duplicate(true)
	_profile = profile.duplicate(true)
	_title.text = "SUCCÈS · %d FAMILLES" % _catalog.size()
	_category.clear()
	_category.add_item("TOUS LES SUCCÈS")
	_categories.clear()
	for definition in _catalog:
		var category := str(definition.get("category", ""))
		if not category.is_empty() and not _categories.has(category):
			_categories.append(category)
	_categories.sort()
	for category in _categories:
		_category.add_item(category.replace("_", " ").to_upper())
	_category.select(0)
	visible = true
	_show_category(0)
	_category.grab_focus()

func present_error() -> void:
	_title.text = "SUCCÈS · INDISPONIBLES"
	_intro.text = "Le profil est indisponible; impossible de charger la progression des succès."
	_category.visible = false
	_entries.visible = false
	visible = true
	_close_button.grab_focus()

func _show_category(index: int) -> void:
	for child in _entries.get_children():
		child.queue_free()
	_entries.visible = true
	_category.visible = true
	var progress: Dictionary = _profile.get("achievement_progress", {})
	var tiers: Dictionary = progress.get("tiers", {})
	var metrics: Dictionary = progress.get("metrics", {})
	var unlocked := 0
	var revealed := 0
	for definition in _catalog:
		var achievement_id := str(definition.get("id", ""))
		var category := str(definition.get("category", ""))
		var metric_value := float(metrics.get(str(definition.get("metric", "")), 0.0))
		var tier_index := int(tiers.get(achievement_id, 0))
		unlocked += tier_index
		if metric_value > 0.0:
			revealed += 1
		if index == 0 or category == _categories[index - 1]:
			_entries.add_child(_make_entry(definition, metric_value, tier_index))
	_intro.text = "PALIERS OBTENUS: %d  ·  FAMILLES RÉVÉLÉES: %d / %d" % [unlocked, revealed, _catalog.size()]

func _make_entry(definition: Dictionary, metric_value: float, tier_index: int) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(0, 42)
	card.add_theme_constant_override("separation", 1)
	var heading := HBoxContainer.new()
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icons/catalog/achievement_medal.png") as Texture2D
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(icon)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 8)
	var tiers: Array = definition.get("tiers", [])
	var secret := bool(definition.get("secret", false))
	var revealed := metric_value > 0.0 or tier_index > 0
	var achievement_name := str(definition.get("name", definition.get("id", ""))).to_upper()
	title.text = "%s  ·  %s" % [achievement_name if revealed or not secret else "SUCCÈS SECRET", \
		TIER_NAMES[tier_index - 1] if tier_index > 0 else "EN COURS"]
	heading.add_child(title)
	card.add_child(heading)
	var next_text := "TOUS LES PALIERS OBTENUS"
	if tier_index < tiers.size():
		var next_tier: Dictionary = tiers[tier_index]
		next_text = "%s · %s: %s / %s" % [TIER_NAMES[tier_index], str(definition.get("metric", "")).replace("_", " ").to_upper(), \
			_format_number(metric_value), _format_number(float(next_tier.get("threshold", 0.0)))]
	var condition := Label.new()
	condition.add_theme_color_override("font_color", Color("#A5AEC3"))
	condition.add_theme_font_size_override("font_size", 7)
	condition.autowrap_mode = 2
	condition.text = next_text if revealed or not secret else "Progressez pour révéler ce succès secret."
	card.add_child(condition)
	var reward := Label.new()
	reward.add_theme_color_override("font_color", Color("#48E69B"))
	reward.add_theme_font_size_override("font_size", 7)
	reward.autowrap_mode = 2
	var reward_lines: Array[String] = []
	if tier_index > 0:
		reward_lines.append(_reward_text(tiers, tier_index))
	if tier_index < tiers.size() and (revealed or not secret):
		reward_lines.append("PROCHAIN: " + _tier_reward_text(tiers[tier_index]))
	reward.text = "  ·  ".join(reward_lines)
	card.add_child(reward)
	var divider := HSeparator.new()
	card.add_child(divider)
	return card

func _reward_text(tiers: Array, tier_index: int) -> String:
	var totals := {}
	for index in range(mini(tier_index, tiers.size())):
		var rewards: Dictionary = tiers[index].get("rewards", {})
		for stat_id in rewards:
			totals[stat_id] = float(totals.get(stat_id, 0.0)) + float(rewards[stat_id])
	var labels: Array[String] = []
	for stat_id in totals:
		labels.append("%s +%.2f%%" % [STAT_NAMES.get(stat_id, str(stat_id).to_upper()), _reward_percent(str(stat_id), float(totals[stat_id]))])
	return "BONUS PERMANENTS: " + (" · ".join(labels) if not labels.is_empty() else "AUCUN")

func _tier_reward_text(tier: Dictionary) -> String:
	var rewards: Dictionary = tier.get("rewards", {})
	var labels: Array[String] = []
	for stat_id in rewards:
		labels.append("%s +%.2f%%" % [STAT_NAMES.get(stat_id, str(stat_id).to_upper()), \
			_reward_percent(str(stat_id), float(rewards[stat_id]))])
	return " · ".join(labels)

func _reward_percent(stat_id: String, amount: float) -> float:
	return amount * 100.0 if stat_id in ["damage_pct", "move_speed_pct", "max_hp_pct"] else amount

func _format_number(value: float) -> String:
	return "%.0f" % value
