extends SceneTree

const DIRECTOR_SCRIPT := preload("res://scripts/survival_wave_director.gd")

func _initialize() -> void:
	var survival = DIRECTOR_SCRIPT.new()
	for _wave in range(12):
		survival.advance(30.0)
	if survival.state != DIRECTOR_SCRIPT.State.MID_BOSS or survival.wave != 12 or \
		not survival.boss_defeated() or survival.wave != 13:
		_fail("Normal Survival should preserve its current wave 12 boss transition")
		return
	var armorless = DIRECTOR_SCRIPT.new(true)
	for boss_wave in [12, 24, 36]:
		while armorless.wave < boss_wave or armorless.state != DIRECTOR_SCRIPT.State.MID_BOSS:
			armorless.advance(30.0)
		if armorless.wave != boss_wave or armorless.state != DIRECTOR_SCRIPT.State.MID_BOSS or \
			not armorless.boss_defeated() or armorless.wave != boss_wave + 1 or \
			armorless.state != DIRECTOR_SCRIPT.State.WAVE:
			_fail("Armorless should continue after each boss every 12 completed waves")
			return
	print("armorless_wave_director_smoke: passed repeated 12-wave boss cadence")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
