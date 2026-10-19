extends Control

signal close_requested

const TIER_NAMES := ["BRONZE", "ARGENT", "OR", "DIAMANT"]
const STAT_NAMES := {
	"damage_pct": "DÉGÂTS", "max_hp_pct": "PV MAX", "move_speed_pct": "VITESSE",
	"attack_speed_pct": "VITESSE D’ATTAQUE", "critical_chance_pct": "CHANCE CRITIQUE",
}
const CATEGORY_NAMES := {
	"combat": "COMBAT", "survival": "SURVIE", "weapons": "ARMES",
	"relics_evolutions": "RELIQUES ET ÉVOLUTIONS", "equipment": "ÉQUIPEMENT",
	"difficulty_bosses": "DIFFICULTÉS ET BOSS", "progression": "PROGRESSION", "secrets": "SECRETS",
}
const METRIC_NAMES := {
	"total_kills": "ENNEMIS ÉLIMINÉS", "highest_wave": "VAGUE ATTEINTE",
	"completed_runs": "RUNS TERMINÉES", "boss_victories": "BOSS VAINCUS",
	"chaos_victories": "VICTOIRES EN CHAOS", "evolutions_in_run": "ÉVOLUTIONS DÉCLENCHÉES",
	"elite_affix_types_defeated": "TYPES D’AFFIXES D’ÉLITE BATTUS",
	"max_weapon_loadout": "ARMES ÉQUIPÉES EN MÊME TEMPS",
	"max_relic_loadout": "RELIQUES ÉQUIPÉES EN MÊME TEMPS",
	"equipment_items_collected": "ÉQUIPEMENTS OBTENUS",
}

@onready var _title: Label = $Center/Panel/Content/Header/Title
@onready var _intro: Label = $Center/Panel/Content/Intro
@onready var _category: OptionButton = $Center/Panel/Content/Category
@onready var _entries: GridContainer = $Center/Panel/Content/Body/BodyRow/EntriesScroll/Entries
@onready var _body: Control = $Center/Panel/Content/Body/BodyRow
@onready var _detail_title: Label = $Center/Panel/Content/Body/BodyRow/Detail/DetailContent/DetailTitle
@onready var _detail_objective: Label = $Center/Panel/Content/Body/BodyRow/Detail/DetailContent/DetailObjective
@onready var _detail_progress: Label = $Center/Panel/Content/Body/BodyRow/Detail/DetailContent/DetailProgress
@onready var _detail_rewards: Label = $Center/Panel/Content/Body/BodyRow/Detail/DetailContent/DetailRewards
@onready var _close_button: Button = $Center/Panel/Content/Header/CloseButton

var _catalog: Array[Dictionary] = []
var _profile: Dictionary = {}
var _categories: Array[String] = []
var _unlocked_tier_count := 0
var _selected_card: PanelContainer

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
		_category.add_item(str(CATEGORY_NAMES.get(category, category.replace("_", " ").to_upper())))
	_category.select(0)
	visible = true
	_show_category(0)
	_category.grab_focus()

func present_error() -> void:
	_title.text = "SUCCÈS · INDISPONIBLES"
	_intro.text = "Le profil est indisponible; impossible de charger la progression des succès."
	_category.visible = false
	_body.visible = false
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
	_unlocked_tier_count = 0
	var revealed := 0
	var selected_definition: Dictionary = {}
	var selected_metric := 0.0
	var selected_tier := 0
	for definition in _catalog:
		var achievement_id := str(definition.get("id", ""))
		var category := str(definition.get("category", ""))
		var metric_value := float(metrics.get(str(definition.get("metric", "")), 0.0))
		var tier_index := int(tiers.get(achievement_id, 0))
		_unlocked_tier_count += tier_index
		if not bool(definition.get("secret", false)) or metric_value > 0.0 or tier_index > 0:
			revealed += 1
		if index == 0 or category == _categories[index - 1]:
			var card := _make_entry(definition, metric_value, tier_index)
			_entries.add_child(card)
			if selected_definition.is_empty():
				selected_definition = definition
				selected_metric = metric_value
				selected_tier = tier_index
				_selected_card = card
	_body.visible = true
	if not selected_definition.is_empty():
		_show_detail(selected_definition, selected_metric, selected_tier)
	_intro.text = "PALIERS OBTENUS : %d / %d  ·  SUCCÈS RÉVÉLÉS : %d / %d" % [
		_unlocked_tier_count, _catalog.size() * TIER_NAMES.size(), revealed, _catalog.size(),
	]

func _make_entry(definition: Dictionary, metric_value: float, tier_index: int) -> Control:
	var card := PanelContainer.new()
	card.name = "AchievementEntry"
	card.custom_minimum_size = Vector2(0, 112)
	var tiers: Array = definition.get("tiers", [])
	var style := StyleBoxFlat.new()
	var secret := bool(definition.get("secret", false))
	var revealed := metric_value > 0.0 or tier_index > 0
	var accent := Color("#FFD447") if tier_index >= tiers.size() else \
		Color("#37E8F5") if revealed or not secret else Color("#6A5588")
	style.bg_color = Color("#182139") if revealed or not secret else Color("#151326")
	style.border_color = accent
	style.set_border_width_all(1)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	card.add_theme_stylebox_override("panel", style)
	card.set_meta("card_style", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_input.bind(card, definition, metric_value, tier_index))
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("achievement_definition", definition)
	card.set_meta("achievement_metric", metric_value)
	card.set_meta("achievement_tier", tier_index)
	card.focus_entered.connect(_on_card_focus.bind(card, definition, metric_value, tier_index))
	var content := VBoxContainer.new()
	content.name = "CardContent"
	content.add_theme_constant_override("separation", 2)
	card.add_child(content)
	var heading := HBoxContainer.new()
	heading.name = "Heading"
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icons/catalog/achievement_medal.png") as Texture2D
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(icon)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 9)
	var achievement_name := str(definition.get("name", definition.get("id", ""))).to_upper()
	title.name = "AchievementName"
	title.add_theme_color_override("font_color", accent)
	title.text = "%s  ·  %s" % [achievement_name if revealed or not secret else "SUCCÈS SECRET", \
		("PALIER %d/4 · %s" % [tier_index, TIER_NAMES[tier_index - 1]]) if tier_index > 0 else "À DÉBLOQUER"]
	heading.add_child(title)
	content.add_child(heading)
	var next_text := "TOUS LES PALIERS OBTENUS"
	var next_threshold := 0.0
	if tier_index < tiers.size():
		var next_tier: Dictionary = tiers[tier_index]
		next_threshold = float(next_tier.get("threshold", 0.0))
		next_text = "OBJECTIF : %s · PROCHAIN PALIER %s" % [
			_describe_metric(str(definition.get("metric", ""))), TIER_NAMES[tier_index],
		]
	var condition := Label.new()
	condition.name = "AchievementObjective"
	condition.add_theme_color_override("font_color", Color("#A5AEC3"))
	condition.add_theme_font_size_override("font_size", 8)
	condition.autowrap_mode = 2
	condition.text = next_text if revealed or not secret else "Réalisez des actions pendant vos runs pour révéler ce succès."
	content.add_child(condition)
	var progress_bar := ProgressBar.new()
	progress_bar.name = "AchievementProgressBar"
	progress_bar.custom_minimum_size = Vector2(0, 6)
	progress_bar.show_percentage = false
	progress_bar.max_value = maxf(next_threshold, 1.0)
	progress_bar.value = minf(metric_value, next_threshold)
	progress_bar.visible = tier_index < tiers.size() and (revealed or not secret)
	var progress_track := StyleBoxFlat.new()
	progress_track.bg_color = Color("#293354")
	progress_track.set_corner_radius_all(0)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color("#37E8F5")
	progress_fill.set_corner_radius_all(0)
	progress_bar.add_theme_stylebox_override("background", progress_track)
	progress_bar.add_theme_stylebox_override("fill", progress_fill)
	content.add_child(progress_bar)
	var progress_label := Label.new()
	progress_label.name = "AchievementProgress"
	progress_label.add_theme_color_override("font_color", Color("#37E8F5"))
	progress_label.add_theme_font_size_override("font_size", 8)
	if tier_index >= tiers.size():
		progress_label.text = "PROGRESSION : TERMINÉ · %d/4 PALIERS" % tiers.size()
	elif revealed or not secret:
		progress_label.text = "PROGRESSION : %s / %s" % [
			_format_number(minf(metric_value, next_threshold)), _format_number(next_threshold),
		]
	else:
		progress_label.text = "PROGRESSION : MASQUÉE"
	content.add_child(progress_label)
	var reward := Label.new()
	reward.name = "AchievementReward"
	reward.add_theme_color_override("font_color", Color("#48E69B"))
	reward.add_theme_font_size_override("font_size", 8)
	reward.autowrap_mode = 2
	var reward_lines: Array[String] = []
	if tier_index > 0:
		reward_lines.append("OBTENU · " + _reward_text(tiers, tier_index))
	if tier_index < tiers.size() and (revealed or not secret):
		reward_lines.append("À GAGNER · " + _tier_reward_text(tiers[tier_index]))
	reward.text = "  ·  ".join(reward_lines)
	content.add_child(reward)
	var divider := HSeparator.new()
	content.add_child(divider)
	return card

func _on_card_input(event: InputEvent, card: PanelContainer, definition: Dictionary, metric_value: float, tier_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_achievement(card, definition, metric_value, tier_index)

func _on_card_focus(card: PanelContainer, definition: Dictionary, metric_value: float, tier_index: int) -> void:
	_select_achievement(card, definition, metric_value, tier_index)

func _select_achievement(card: PanelContainer, definition: Dictionary, metric_value: float, tier_index: int) -> void:
	if is_instance_valid(_selected_card):
		var previous_style: StyleBoxFlat = _selected_card.get_meta("card_style")
		previous_style.border_color = previous_style.bg_color
	_selected_card = card
	var selected_style: StyleBoxFlat = card.get_meta("card_style")
	selected_style.border_color = Color("#FFD447")
	_show_detail(definition, metric_value, tier_index)

func _show_detail(definition: Dictionary, metric_value: float, tier_index: int) -> void:
	var tiers: Array = definition.get("tiers", [])
	var hidden := bool(definition.get("secret", false)) and metric_value <= 0.0 and tier_index == 0
	var name := "SUCCÈS SECRET" if hidden else str(definition.get("name", definition.get("id", ""))).to_upper()
	_detail_title.text = "%s · %d/4 PALIERS" % [name, tier_index]
	_detail_objective.text = "Condition masquée. Progressez pendant vos runs pour révéler ce succès." if hidden else _describe_metric(str(definition.get("metric", "")))
	if hidden:
		_detail_progress.text = "PROGRESSION · ???"
		_detail_rewards.text = "RÉCOMPENSE · ???"
		return
	if tier_index >= tiers.size():
		_detail_progress.text = "TERMINÉ · %d/4 PALIERS" % tiers.size()
	else:
		var tier: Dictionary = tiers[tier_index]
		var threshold := float(tier.get("threshold", 0.0))
		_detail_progress.text = "%s / %s · PROCHAIN PALIER %s" % [
			_format_number(minf(metric_value, threshold)), _format_number(threshold), TIER_NAMES[tier_index],
		]
		_detail_rewards.text = "À GAGNER · " + _tier_reward_text(tier)
	if tier_index > 0:
		_detail_rewards.text = "OBTENU · " + _reward_text(tiers, tier_index) + "\n" + _detail_rewards.text

func _reward_text(tiers: Array, tier_index: int) -> String:
	var totals := {}
	for index in range(mini(tier_index, tiers.size())):
		var rewards: Dictionary = tiers[index].get("rewards", {})
		for stat_id in rewards:
			totals[stat_id] = float(totals.get(stat_id, 0.0)) + float(rewards[stat_id])
	var labels: Array[String] = []
	for stat_id in totals:
		labels.append("%s +%.2f%%" % [STAT_NAMES.get(stat_id, str(stat_id).to_upper()), _reward_percent(str(stat_id), float(totals[stat_id]))])
	return " · ".join(labels) if not labels.is_empty() else "AUCUN"

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
	var whole := str(roundi(value))
	var fraction := ""
	if not is_equal_approx(value, roundf(value)):
		var formatted := "%.1f" % value
		var decimal_index := formatted.find(".")
		whole = formatted.substr(0, decimal_index)
		fraction = "," + formatted.substr(decimal_index + 1)
	var grouped := ""
	while whole.length() > 3:
		grouped = " " + whole.substr(whole.length() - 3) + grouped
		whole = whole.substr(0, whole.length() - 3)
	return whole + grouped + fraction

func _describe_metric(metric_id: String) -> String:
	if METRIC_NAMES.has(metric_id):
		return METRIC_NAMES[metric_id]
	for prefix in ["enemy_kills_", "weapon_kills_", "weapon_damage_", "max_weapon_level_", \
		"max_relic_level_", "elite_affix_kills_", "equipment_rarity_", "equipment_slot_", \
		"runs_at_difficulty_", "boss_victories_at_difficulty_"]:
		if metric_id.begins_with(prefix):
			var subject := _humanize_id(metric_id.trim_prefix(prefix))
			if prefix == "enemy_kills_": return "ENNEMIS ÉLIMINÉS · %s" % subject
			if prefix == "weapon_kills_": return "ÉLIMINATIONS AVEC · %s" % subject
			if prefix == "weapon_damage_": return "DÉGÂTS INFLIGÉS AVEC · %s" % subject
			if prefix == "max_weapon_level_": return "NIVEAU D’ARME · %s" % subject
			if prefix == "max_relic_level_": return "NIVEAU DE RELIQUE · %s" % subject
			if prefix == "elite_affix_kills_": return "ÉLITES BATTUES · AFFIXE %s" % subject
			if prefix == "equipment_rarity_": return "ÉQUIPEMENTS OBTENUS · RARETÉ %s" % subject
			if prefix == "equipment_slot_": return "ÉQUIPEMENTS OBTENUS · EMPLACEMENT %s" % subject
			if prefix == "runs_at_difficulty_": return "RUNS TERMINÉES · DIFFICULTÉ %s" % subject
			return "BOSS VAINCUS · DIFFICULTÉ %s" % subject
	return _humanize_id(metric_id)

func _humanize_id(value: String) -> String:
	return value.replace("_", " ").capitalize()
