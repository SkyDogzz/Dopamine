extends RefCounted

const ORDER := ["easy", "normal", "hard", "nightmare", "chaos"]

# [PROPOSÉ] Values from GDD v1.6; centralize them for later tuning.
const DATA := {
	"easy": {"enemy_hp": 0.75, "enemy_damage": 0.70, "density": 0.80, "essence": 0.70, "powder": 0.70},
	"normal": {"enemy_hp": 1.00, "enemy_damage": 1.00, "density": 1.00, "essence": 1.00, "powder": 1.00},
	"hard": {"enemy_hp": 1.50, "enemy_damage": 1.30, "density": 1.20, "essence": 1.60, "powder": 1.50},
	"nightmare": {"enemy_hp": 2.20, "enemy_damage": 1.70, "density": 1.50, "essence": 2.50, "powder": 2.30},
	"chaos": {"enemy_hp": 3.20, "enemy_damage": 2.30, "density": 1.80, "essence": 4.00, "powder": 3.50},
}
