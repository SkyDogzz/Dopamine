extends Control

signal close_requested

const ENTRIES := [
	{"id": "chaser", "name": "CHASER", "role": "Archétype de mêlée du prototype.", "status": "Famille mêlée validée · profil proposé"},
	{"id": "sprinter", "name": "SPRINTER", "role": "Archétype rapide du prototype.", "status": "Famille rapide validée · profil proposé"},
	{"id": "tank", "name": "TANK", "role": "Archétype résistant du prototype.", "status": "Famille tank validée · profil proposé"},
	{"id": "shooter", "name": "SHOOTER", "role": "Archétype à distance; ses projectiles sont télégraphiés.", "status": "Famille distance validée · profil proposé"},
	{"id": "buffer", "name": "BUFFER", "role": "Soutien qui renforce les ennemis proches.", "status": "Famille soutien validée · valeurs proposées"},
	{"id": "exploder", "name": "EXPLODER", "role": "Explosif avec une attaque de proximité esquivable.", "status": "Famille explosive validée · valeurs proposées"},
	{"id": "shielder", "name": "SHIELDER", "role": "Soutien qui protège les ennemis alliés.", "status": "Famille soutien validée · valeurs proposées"},
	{"id": "summoner", "name": "SUMMONER", "role": "Soutien qui invoque des ennemis.", "status": "Famille soutien validée · valeurs proposées"},
	{"id": "summoned", "name": "SUMMONED", "role": "Unité invoquée du prototype.", "status": "Profil prototype"},
	{"id": "elite_sprinter", "name": "ÉLITE", "role": "Ennemi d’élite avec un ou plusieurs affixes.", "status": "Élites validées · affixes et valeurs proposés"},
	{"id": "boss_pulse_warden", "name": "PULSE WARDEN", "role": "Boss avec phases et patterns télégraphiés.", "status": "Boss validé · patterns et valeurs proposés"},
	{"id": "boss_dopamine_core", "name": "DOPAMINE CORE", "role": "Boss final avec phases et patterns télégraphiés.", "status": "Boss validé · patterns et valeurs proposés"},
]
const ENEMY_COUNT := 12

const SPRITE_PATH := "res://assets/sprites/roster/%s.png"
const COMBAT_CATALOG_SCRIPT := preload("res://scripts/combat_catalog.gd")
const WEAPON_DESCRIPTIONS := {
	"lightning_conductor": "Tire un éclair sur l’ennemi le plus proche, puis le fait rebondir vers les cibles voisines.",
	"inferno_sprayer": "Projette du feu et brûle la cible touchée.",
	"crimson_daggers": "Fait orbiter des dagues autour du joueur.",
	"void_orb": "Envoie un orbe lent qui traverse les ennemis et attire ceux qui sont proches.",
	"frost_nova": "Blesse et ralentit les ennemis autour du joueur.",
	"minigun": "Tire rapidement sur l’ennemi le plus proche.",
	"meteor_staff": "Vise un groupe d’ennemis et provoque une explosion à l’impact.",
	"sawblades": "Envoie une scie qui rebondit entre les ennemis.",
	"toxic_cloud": "Crée un nuage qui blesse et empoisonne les ennemis proches.",
	"prism_laser": "Priorise l’ennemi avec le plus de PV dans un groupe dense.",
}
const RELIC_DESCRIPTIONS := {
	"storm_core": "Augmente les dégâts globaux.",
	"infernal_heart": "Augmente la vitesse d’attaque globale.",
	"blood_chalice": "Augmente le lifesteal et les soins par élimination.",
	"singularity": "Réduit les cooldowns globaux.",
	"frozen_crown": "Augmente la zone des attaques.",
	"overdrive_engine": "Augmente la vitesse d’attaque globale.",
	"celestial_eye": "Augmente la zone des attaques.",
	"magnetic_coil": "Augmente la vitesse des projectiles.",
	"plague_mask": "Augmente les dégâts globaux.",
	"prism_crystal": "Augmente les dégâts critiques.",
	"magnet_heart": "Augmente le rayon de collecte des orbes XP; n’attire pas les coffres.",
}
const EVOLUTION_NAMES := {
	"infinite_circuit": "Infinite Circuit", "wildfire": "Wildfire", "bloodstorm": "Bloodstorm",
	"event_horizon": "Event Horizon", "absolute_zero": "Absolute Zero", "redline": "Redline",
	"starfall": "Starfall", "razorstorm": "Razorstorm", "pandemic": "Pandemic",
	"spectrum_collapse": "Spectrum Collapse",
}

@onready var _entries: GridContainer = $Center/Panel/Content/Body/EntryScroll/Entries
@onready var _detail_portrait: TextureRect = $Center/Panel/Content/Body/Detail/DetailContent/Portrait
@onready var _detail_title: Label = $Center/Panel/Content/Body/Detail/DetailContent/DetailTitle
@onready var _detail_status: Label = $Center/Panel/Content/Body/Detail/DetailContent/DetailStatus
@onready var _detail_description: Label = $Center/Panel/Content/Body/Detail/DetailContent/DetailDescription
@onready var _close_button: Button = $Center/Panel/Content/Header/CloseButton
@onready var _category: TabBar = $Center/Panel/Content/Category
@onready var _intro: Label = $Center/Panel/Content/Intro
@onready var _title: Label = $Center/Panel/Content/Header/Title
@onready var _panel_frame: PanelContainer = $Center/Panel

var _combat_catalog: RefCounted
var _seen_enemies: Dictionary = {}
var _unlocked_weapons: Dictionary = {}
var _unlocked_relics: Dictionary = {}
var _selected_card: PanelContainer

func _ready() -> void:
	_fit_panel_to_viewport()
	get_viewport().size_changed.connect(_fit_panel_to_viewport)
	_combat_catalog = COMBAT_CATALOG_SCRIPT.new()
	_category.add_tab("ENNEMIS")
	_category.add_tab("ARMES ET COMBOS")
	_category.add_tab("RELIQUES")
	_category.tab_selected.connect(_show_category)
	_close_button.pressed.connect(func() -> void: close_requested.emit())

func _fit_panel_to_viewport() -> void:
	var available := get_viewport_rect().size - Vector2(32.0, 32.0)
	_panel_frame.custom_minimum_size = Vector2(minf(1150.0, available.x), minf(650.0, available.y))
	_entries.columns = 3 if available.x >= 1100.0 else 2 if available.x >= 700.0 else 1

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()

func present(progress: Dictionary) -> void:
	visible = true
	_title.text = "CODEX · CONTENU"
	_intro.text = "Armes/reliques liées aux déblocages; ennemis révélés à la première rencontre."
	_category.visible = true
	_entries.visible = true
	_seen_enemies = _to_lookup(progress.get("seen_enemies", []))
	_unlocked_weapons = _to_lookup(progress.get("unlocked_weapons", []))
	_unlocked_relics = _to_lookup(progress.get("unlocked_relics", []))
	_category.current_tab = 0
	_show_category(0)
	_category.grab_focus()

func present_error() -> void:
	visible = true
	_title.text = "CODEX · INDISPONIBLE"
	_intro.text = "Le profil est indisponible; impossible de charger l’état de progression du Codex."
	_category.visible = false
	$Center/Panel/Content/Body.visible = false
	_close_button.grab_focus()

func _to_lookup(ids: Array) -> Dictionary:
	var result := {}
	for item_id in ids:
		result[str(item_id)] = true
	return result

func _count_unlocked(unlocked: Dictionary, catalog_entries: Dictionary) -> int:
	var count := 0
	for item_id in catalog_entries:
		if unlocked.has(item_id):
			count += 1
	return count

func _show_category(index: int) -> void:
	_entries.columns = 1 if index == 1 else 3 if get_viewport_rect().size.x >= 1100.0 else 1
	for child in _entries.get_children():
		child.queue_free()
	_selected_card = null
	_set_detail("SÉLECTIONNEZ UNE FICHE", "", "Choisissez un ennemi, une arme, une relique ou une évolution dans la liste.", "")
	if index == 0:
		_intro.text = "Ennemis rencontrés: %d / %d" % [_seen_enemies.size(), ENEMY_COUNT]
		for entry in ENTRIES:
			var card := _make_entry(entry)
			_entries.add_child(card)
			if _selected_card == null:
				_select_codex_entry(card)
	elif index == 1:
		_intro.text = "ARMES DÉBLOQUÉES: %d / %d" % [_count_unlocked(_unlocked_weapons, _combat_catalog.weapons), _combat_catalog.weapons.size()]
		_show_weapons()
	else:
		_intro.text = "RELIQUES DÉBLOQUÉES: %d / %d" % [_count_unlocked(_unlocked_relics, _combat_catalog.relics), _combat_catalog.relics.size()]
		_show_relics()

func _show_weapons() -> void:
	var weapons: Dictionary = _combat_catalog.weapons
	var relics: Dictionary = _combat_catalog.relics
	for weapon_id in weapons:
		var weapon: Dictionary = weapons[weapon_id]
		var relic: Dictionary = relics.get(str(weapon["relic_id"]), {})
		var unlocked := _unlocked_weapons.has(weapon_id)
		var weapon_icon_path := "res://assets/sprites/catalog/weapon_%s.png" % weapon_id if unlocked else ""
		var combo_name := str(EVOLUTION_NAMES.get(str(weapon["evolution_id"]), weapon["evolution_id"])).to_upper()
		var relic_unlocked := _unlocked_relics.has(str(weapon["relic_id"]))
		var combo_text := "ARME DÉBLOQUÉE · Combo: %s + %s → %s" % [str(weapon["name"]), \
			str(relic["name"]), combo_name] if unlocked and relic_unlocked else \
			"ARME %s · combo verrouillé (arme et relique niveau 5)" % ("DÉBLOQUÉE" if unlocked else "VERROUILLÉE")
		var card := _make_catalog_entry(
			str(weapon["name"]), str(WEAPON_DESCRIPTIONS.get(weapon_id, weapon["behavior"])), combo_text, weapon_icon_path,
			"Évolution offerte quand l’arme et sa relique atteignent le niveau 5." if unlocked else "", str(weapon_id)
		)
		_entries.add_child(card)
		if _selected_card == null:
			_select_codex_entry(card)

func _show_relics() -> void:
	var relics: Dictionary = _combat_catalog.relics
	var weapons: Dictionary = _combat_catalog.weapons
	for relic_id in relics:
		var relic: Dictionary = relics[relic_id]
		var linked_weapon_id := str(relic.get("weapon_id", ""))
		var linked_weapon: Dictionary = weapons.get(linked_weapon_id, {})
		var unlocked := _unlocked_relics.has(relic_id)
		var icon_path := "res://assets/sprites/catalog/relic_%s.png" % relic_id if unlocked else ""
		var status := "Relique globale · bonus chiffrés [PROPOSÉS]" if unlocked else "VERROUILLÉE · arbre de compétences"
		if not linked_weapon.is_empty():
			if unlocked and _unlocked_weapons.has(linked_weapon_id):
				status = "Combo: %s + %s → %s" % [str(linked_weapon["name"]), str(relic["name"]), \
					str(EVOLUTION_NAMES.get(str(linked_weapon["evolution_id"]), linked_weapon["evolution_id"])).to_upper()]
			else:
				status = "%s · combo verrouillé" % ("RELIQUE DÉBLOQUÉE" if unlocked else "RELIQUE VERROUILLÉE")
		var card := _make_catalog_entry(
			str(relic["name"]), "%s Bonus par niveau [PROPOSÉ]: %s." % [
				str(RELIC_DESCRIPTIONS.get(relic_id, relic["behavior"])),
				str(relic.get("global_bonus_per_level", "—")),
			], status,
			icon_path, "Bonus chiffrés marqués [PROPOSÉS] dans le catalogue de combat", str(relic_id)
		)
		_entries.add_child(card)
		if _selected_card == null:
			_select_codex_entry(card)

func _make_entry(entry: Dictionary) -> Control:
	var entry_id := str(entry["id"])
	var path := SPRITE_PATH % (entry_id if entry_id.begins_with("boss_") else "enemy_%s" % entry_id)
	var runtime_id: String = str({"elite_sprinter": "elite", "boss_pulse_warden": "mid_boss", \
		"boss_dopamine_core": "final_boss"}.get(entry_id, entry_id))
	var seen := _seen_enemies.has(runtime_id)
	return _make_catalog_entry(str(entry["name"]) if seen else "INCONNU", \
		str(entry["role"]) if seen else "Rencontrez cet ennemi pendant une run pour révéler cette fiche.", \
		str(entry["status"]) if seen else "NON RENCONTRÉ", path if seen else "", "", entry_id if seen else "", false)

func _make_catalog_entry(title_text: String, description: String, status_text: String, icon_path: String, tooltip: String, key: String = "", selectable: bool = true) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 68)
	var style := StyleBoxFlat.new()
	var is_locked := status_text.contains("VERROUILLÉ") or status_text.contains("NON RENCONTRÉ")
	style.bg_color = Color("#10172B") if is_locked else Color("#14243A")
	style.border_color = Color("#39486B") if is_locked else Color("#243B65")
	style.set_border_width_all(1)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	card.add_theme_stylebox_override("panel", style)
	card.set_meta("card_style", style)
	card.set_meta("codex_title", title_text)
	card.set_meta("codex_status", status_text)
	card.set_meta("codex_description", description)
	card.set_meta("codex_icon", icon_path)
	if selectable:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(card, title_text, status_text, description, icon_path, key))
		card.focus_mode = Control.FOCUS_ALL
		card.focus_entered.connect(_on_card_focus.bind(card, title_text, status_text, description, icon_path))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	card.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = load(icon_path) as Texture2D if not icon_path.is_empty() and ResourceLoader.exists(icon_path) else null
	portrait.custom_minimum_size = Vector2(42, 42)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	if portrait.texture == null:
		var unknown_mark := Label.new()
		unknown_mark.text = "?"
		unknown_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		unknown_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unknown_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		unknown_mark.add_theme_font_size_override("font_size", 14)
		unknown_mark.add_theme_color_override("font_color", Color("#586381"))
		portrait.add_child(unknown_mark)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	var name := Label.new()
	name.text = title_text
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.tooltip_text = tooltip
	name.add_theme_font_size_override("font_size", 9)
	name.add_theme_color_override("font_color", Color("#37E8F5"))
	copy.add_child(name)
	var details := Label.new()
	details.text = description
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 8)
	details.add_theme_color_override("font_color", Color("#A5AEC3"))
	copy.add_child(details)
	var status := Label.new()
	status.text = status_text
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 6)
	status.add_theme_color_override("font_color", Color("#A6AEC4") if is_locked else Color("#48E69B"))
	copy.add_child(status)
	return card

func _on_card_input(event: InputEvent, card: PanelContainer, title_text: String, status_text: String, description: String, icon_path: String, key: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_selected_card(card)
		_set_detail(title_text, status_text, description, icon_path)
		if not key.is_empty() and key.begins_with("boss_"):
			_detail_description.text += "\n\nBoss à phases : patterns détaillés dans la documentation de conception."

func _on_card_focus(card: PanelContainer, title_text: String, status_text: String, description: String, icon_path: String) -> void:
	_set_selected_card(card)
	_set_detail(title_text, status_text, description, icon_path)

func _set_selected_card(card: PanelContainer) -> void:
	if is_instance_valid(_selected_card):
		var previous_style: StyleBoxFlat = _selected_card.get_meta("card_style")
		previous_style.border_color = Color("#243B65")
	if is_instance_valid(card):
		var selected_style: StyleBoxFlat = card.get_meta("card_style")
		selected_style.border_color = Color("#FFD447")
		_selected_card = card

func _set_detail(title_text: String, status_text: String, description: String, icon_path: String) -> void:
	_detail_title.text = title_text
	_detail_status.text = status_text
	_detail_description.text = description
	_detail_portrait.texture = load(icon_path) as Texture2D if not icon_path.is_empty() and ResourceLoader.exists(icon_path) else null

func _select_codex_entry(card: PanelContainer) -> void:
	_set_selected_card(card)
	_set_detail(str(card.get_meta("codex_title")), str(card.get_meta("codex_status")), \
		str(card.get_meta("codex_description")), str(card.get_meta("codex_icon")))
