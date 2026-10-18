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

@onready var _entries: VBoxContainer = $Center/Panel/Content/Body/Entries
@onready var _close_button: Button = $Center/Panel/Content/Header/CloseButton
@onready var _category: OptionButton = $Center/Panel/Content/Category

var _combat_catalog: RefCounted

func _ready() -> void:
	_combat_catalog = COMBAT_CATALOG_SCRIPT.new()
	_category.add_item("ENNEMIS")
	_category.add_item("ARMES ET COMBOS")
	_category.add_item("RELIQUES")
	_category.item_selected.connect(_show_category)
	_close_button.pressed.connect(func() -> void: close_requested.emit())

func present() -> void:
	visible = true
	_category.select(0)
	_show_category(0)
	_category.grab_focus()

func _show_category(index: int) -> void:
	for child in _entries.get_children():
		child.queue_free()
	if index == 0:
		for entry in ENTRIES:
			_entries.add_child(_make_entry(entry))
	elif index == 1:
		_show_weapons()
	else:
		_show_relics()

func _show_weapons() -> void:
	var weapons: Dictionary = _combat_catalog.weapons
	var relics: Dictionary = _combat_catalog.relics
	for weapon_id in weapons:
		var weapon: Dictionary = weapons[weapon_id]
		var relic: Dictionary = relics.get(str(weapon["relic_id"]), {})
		var weapon_icon_path := "res://assets/sprites/catalog/weapon_%s.png" % weapon_id
		var combo_name := str(EVOLUTION_NAMES.get(str(weapon["evolution_id"]), weapon["evolution_id"])).to_upper()
		var combo_text := "%s + %s → %s" % [str(weapon["name"]), str(relic.get("name", "RELIQUE")), combo_name]
		_entries.add_child(_make_catalog_entry(
			str(weapon["name"]), str(WEAPON_DESCRIPTIONS.get(weapon_id, weapon["behavior"])), combo_text,
			weapon_icon_path, "Arme et évolution · conditions détaillées dans le jeu"
		))

func _show_relics() -> void:
	var relics: Dictionary = _combat_catalog.relics
	var weapons: Dictionary = _combat_catalog.weapons
	for relic_id in relics:
		var relic: Dictionary = relics[relic_id]
		var linked_weapon_id := str(relic.get("weapon_id", ""))
		var linked_weapon: Dictionary = weapons.get(linked_weapon_id, {})
		var icon_path := "res://assets/sprites/catalog/relic_%s.png" % relic_id
		var status := "Relique globale · bonus chiffrés [PROPOSÉS]"
		if not linked_weapon.is_empty():
			status = "Combo: %s + %s → %s" % [str(linked_weapon["name"]), str(relic["name"]), \
				str(EVOLUTION_NAMES.get(str(linked_weapon["evolution_id"]), linked_weapon["evolution_id"])).to_upper()]
		_entries.add_child(_make_catalog_entry(
			str(relic["name"]), "%s Bonus par niveau [PROPOSÉ]: %s." % [
				str(RELIC_DESCRIPTIONS.get(relic_id, relic["behavior"])),
			str(relic.get("global_bonus_per_level", "—")),
			], status,
			icon_path, "Bonus chiffrés marqués [PROPOSÉS] dans le catalogue de combat"
		))

func _make_entry(entry: Dictionary) -> Control:
	var entry_id := str(entry["id"])
	var path := SPRITE_PATH % (entry_id if entry_id.begins_with("boss_") else "enemy_%s" % entry_id)
	return _make_catalog_entry(str(entry["name"]), str(entry["role"]), str(entry["status"]), path, "")

func _make_catalog_entry(title_text: String, description: String, status_text: String, icon_path: String, tooltip: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 37)
	row.add_theme_constant_override("separation", 6)
	var portrait := TextureRect.new()
	portrait.texture = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	portrait.custom_minimum_size = Vector2(32, 32)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	var name := Label.new()
	name.text = title_text
	name.tooltip_text = tooltip
	name.add_theme_font_size_override("font_size", 8)
	name.add_theme_color_override("font_color", Color("#37E8F5"))
	copy.add_child(name)
	var details := Label.new()
	details.text = "%s  ·  %s" % [description, status_text]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 6)
	details.add_theme_color_override("font_color", Color("#A5AEC3"))
	copy.add_child(details)
	return row
