extends SceneTree

const CRITICAL_IMPACT_CAPTURE := "/tmp/dopamine-critical-hit-impact.png"
const DAMAGE_NUMBER_CAPTURE := "/tmp/dopamine-aggregated-damage-number.png"
const STATUS_RING_ANNULI := {
	"burn": Vector2(12.0, 18.0), "poison": Vector2(12.0, 18.0), "bleed": Vector2(12.0, 18.0),
	"chill": Vector2(8.0, 15.0), "shock": Vector2(16.0, 22.0),
}

var _settings: SettingsService

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_settings = root.get_node("Settings") as SettingsService
	_settings.set_reduced_visual_effects_enabled(false)
	var session: Node2D = load("res://scenes/survival_session.tscn").instantiate()
	session.sandbox_diagnostics_enabled = true
	session.sandbox_rng_seed = 9137
	session.skip_starting_weapon_choice = true
	session.spawn_initial_enemy = false
	session.wave_spawning_enabled = false
	session.weapon_enabled = false
	root.add_child(session)
	await process_frame
	if session.simulation == null:
		_fail("Survival session failed to initialize")
		return
	var target_position: Vector2 = session.player.global_position + Vector2(80.0, 0.0)
	if session.simulation.spawn_enemy("chaser", 1, target_position, Vector2.ZERO, 100.0) <= 0:
		_fail("Could not spawn a target for the native critical-hit visual check")
		return
	var target_deadline := Time.get_ticks_msec() + 3000
	while session.simulation.snapshot()["entities"].is_empty() and Time.get_ticks_msec() < target_deadline:
		await process_frame
	if session.simulation.snapshot()["entities"].is_empty():
		_fail("The native critical-hit target did not spawn")
		return
	var projectile_sequence: int = session.simulation.spawn_projectile(
		"minigun", target_position - Vector2(30.0, 0.0), Vector2.RIGHT * 2000.0,
		10.0, 3.0, 1.0, 2.0, 0.5, 2.0, 0.0, 0.0, 0, 0.0, 0.0,
		false, 0.0, 1.0, 1.0, 0.0, 0, 1, true)
	if projectile_sequence <= 0 or not await _wait_for_critical_impact(session):
		_fail("A native critical projectile should produce a critical weapon impact")
		return
	if session._damage_numbers.size() != 1 or not bool(session._damage_numbers[0]["critical"]):
		_fail("A native critical damage event should produce a highlighted damage number")
		return
	session._damage_numbers.clear()
	var aggregation_time: float = session._last_simulation_time
	session._add_damage_number(4.0, target_position, "target", false, aggregation_time)
	session._add_damage_number(6.0, target_position, "target", false, aggregation_time + 0.05)
	session._add_damage_number(2.0, target_position, "target", true, aggregation_time + 0.06)
	if session._damage_numbers.size() != 2 or \
		not is_equal_approx(float(session._damage_numbers[0]["amount"]), 10.0) or \
		not bool(session._damage_numbers[1]["critical"]):
		_fail("Rapid hits on one target should aggregate while preserving a separate critical callout")
		return
	session._damage_numbers.clear()
	var camera := session.player.get_node("Camera2D") as Camera2D
	if session._camera_shake_strength <= 0.0:
		_fail("A native direct damage event should trigger visual camera shake")
		return
	await process_frame
	if camera.offset.is_zero_approx():
		_fail("The direct damage camera shake should reach the active Camera2D")
		return
	await create_timer(0.15).timeout
	session._weapon_impacts.clear()
	session._damage_numbers.clear()
	session._add_damage_number(15.0, target_position, "pause", false, session._last_simulation_time)
	var pause_sequence: int = session.simulation.pause()
	var pause_deadline := Time.get_ticks_msec() + 1500
	var pause_state: Dictionary = session.simulation.snapshot()
	while (not bool(pause_state["paused"]) or int(pause_state["last_sequence"]) < pause_sequence) and \
			Time.get_ticks_msec() < pause_deadline:
		await process_frame
		pause_state = session.simulation.snapshot()
	if not bool(pause_state["paused"]) or int(pause_state["last_sequence"]) < pause_sequence:
		_fail("The simulation should acknowledge the pause before checking visual lifetimes")
		return
	var paused_time: float = float(pause_state["simulation_time"])
	var number_lifetime: float = float(session._damage_numbers[0]["expires_at"]) - session._last_simulation_time
	await create_timer(number_lifetime + 0.1).timeout
	if session._damage_numbers.is_empty() or \
		float(session.simulation.snapshot()["simulation_time"]) != paused_time:
		_fail("Damage numbers should remain visible while simulation time is paused")
		return
	session._damage_numbers.clear()
	session.set_process(false)
	await process_frame
	var shake_state_before: Dictionary = session.simulation.snapshot()
	session._start_screen_shake(100.0)
	session._update_screen_shake(0.03)
	if not is_equal_approx(session._camera_shake_strength, 2.0) or camera.offset.is_zero_approx():
		_fail("A powerful direct impact should produce bounded visual camera shake")
		return
	_settings.set_reduced_visual_effects_enabled(true)
	if not camera.offset.is_zero_approx() or session._camera_shake_strength != 0.0:
		_fail("Reduced visual effects should clear camera shake immediately")
		return
	_settings.set_reduced_visual_effects_enabled(false)
	session._start_screen_shake(1000.0)
	if session._camera_shake_strength > session.screen_shake_max_offset:
		_fail("Camera shake must stay within its configured maximum offset")
		return
	session._update_screen_shake(session.screen_shake_duration_seconds)
	if not camera.offset.is_zero_approx() or session._camera_shake_strength != 0.0:
		_fail("Camera shake should return to its base offset when its active duration expires")
		return
	var shake_state_after: Dictionary = session.simulation.snapshot()
	if shake_state_after["entities"] != shake_state_before["entities"] or \
		int(shake_state_after["last_sequence"]) != int(shake_state_before["last_sequence"]):
		_fail("Screen shake must not change combat entities or simulation sequence")
		return
	var state_before: Dictionary = session.simulation.snapshot()
	if "--capture" in OS.get_cmdline_user_args() and not await _verify_damage_number_capture(session):
		return
	if "--capture" in OS.get_cmdline_user_args() and not await _verify_impact_capture(session):
		return
	if "--capture" in OS.get_cmdline_user_args() and not await _verify_status_capture(session):
		return
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	session._add_weapon_impact("inferno_sprayer", Vector2.RIGHT * 20.0, false, true)
	session._add_enemy_death_pixels("chaser", Vector2.ZERO)
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	if session._weapon_impacts.size() != 2 or \
		bool(session._weapon_impacts[0].get("critical_hit", true)) or \
		bool(session._weapon_impacts[1].get("critical_hit", false)) != true or \
		float(session._weapon_impacts[1].get("emphasis_scale", 1.0)) <= \
		float(session._weapon_impacts[0].get("emphasis_scale", 1.0)) or \
		session._enemy_death_pixels.size() != 8 or \
		session._lightning_arcs.size() != 1:
		_fail("Critical direct hits should retain metadata and receive visible size emphasis")
		return
	var normal_impact_next_random := _next_impact_random(session, false)
	var reduced_impact_next_random := _next_impact_random(session, true)
	var normal_arc_next_random := _next_arc_random(session, false)
	var reduced_arc_next_random := _next_arc_random(session, true)
	if not is_equal_approx(normal_impact_next_random, reduced_impact_next_random) or \
		not is_equal_approx(normal_arc_next_random, reduced_arc_next_random):
		_fail("Reduced visual effects must not change the gameplay random stream")
		return
	_settings.set_reduced_visual_effects_enabled(true)
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	session._add_enemy_death_pixels("chaser", Vector2.ZERO)
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	if not session._visual_effects_reduced() or not session._weapon_impacts.is_empty() or \
		not session._enemy_death_pixels.is_empty() or not session._lightning_arcs.is_empty():
		_fail("Reduced effects should clear and suppress impact, death and lightning visuals")
		return
	var state_after: Dictionary = session.simulation.snapshot()
	if not bool(state_after["paused"]) or int(state_after["last_sequence"]) != int(state_before["last_sequence"]) or \
		state_after["entities"].size() != state_before["entities"].size():
		_fail("Changing visual effects must not advance or alter combat simulation")
		return
	_settings.set_reduced_visual_effects_enabled(false)
	if not session._weapon_impacts.is_empty() or not session._enemy_death_pixels.is_empty() or \
		not session._lightning_arcs.is_empty():
		_fail("Re-enabling effects should not replay visuals that were already on screen")
		return
	session.queue_free()
	await process_frame
	print("survival_visual_effects_smoke: passed")
	quit(0)

func _verify_impact_capture(session: Node2D) -> bool:
	var impact_position := Vector2(180.0, 90.0)
	var screen_position: Vector2 = session.get_global_transform_with_canvas() * impact_position
	session._weapon_impacts.clear()
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var baseline: Image = root.get_texture().get_image()
	session._add_weapon_impact("inferno_sprayer", impact_position, false)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var normal_image: Image = root.get_texture().get_image()
	var normal_pixels := _count_changed_pixels(baseline, normal_image, screen_position)
	session._weapon_impacts.clear()
	session._add_weapon_impact("inferno_sprayer", impact_position, false, true)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var critical_image: Image = root.get_texture().get_image()
	var critical_pixels := _count_changed_pixels(baseline, critical_image, screen_position)
	if critical_pixels <= normal_pixels or normal_pixels < 8:
		_fail("Rendered critical impact should visibly cover more pixels than a normal impact")
		return false
	print("Critical impact changed pixels: normal=%d critical=%d" % [normal_pixels, critical_pixels])
	if critical_image.save_png(CRITICAL_IMPACT_CAPTURE) != OK:
		_fail("Could not save the critical impact visual capture")
		return false
	session._weapon_impacts.clear()
	return true

func _verify_damage_number_capture(session: Node2D) -> bool:
	var position := Vector2(180.0, 90.0)
	var screen_position: Vector2 = session.get_global_transform_with_canvas() * position
	session._damage_numbers.clear()
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var baseline: Image = root.get_texture().get_image()
	session._add_damage_number(73.0, position, "capture", false, session._last_simulation_time)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var normal_render: Image = root.get_texture().get_image()
	var normal_pixels := _count_changed_pixels(baseline, normal_render, screen_position)
	session._damage_numbers.clear()
	session._add_damage_number(73.0, position, "capture", true, session._last_simulation_time)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	var changed_pixels := _count_changed_pixels(baseline, rendered, screen_position)
	if normal_pixels < 8 or changed_pixels <= normal_pixels:
		_fail("Normal damage numbers should render and critical numbers should have visible emphasis")
		return false
	if rendered.save_png(DAMAGE_NUMBER_CAPTURE) != OK:
		_fail("Could not save the aggregated damage number capture")
		return false
	session._damage_numbers.clear()
	print("Damage number changed pixels: normal=%d critical=%d" % [normal_pixels, changed_pixels])
	return true

func _count_changed_pixels(baseline: Image, rendered: Image, center: Vector2) -> int:
	var changed := 0
	for y in range(maxi(0, int(center.y) - 40), mini(rendered.get_height(), int(center.y) + 41)):
		for x in range(maxi(0, int(center.x) - 40), mini(rendered.get_width(), int(center.x) + 41)):
			if baseline.get_pixel(x, y).is_equal_approx(rendered.get_pixel(x, y)):
				continue
			changed += 1
	return changed

func _wait_for_critical_impact(session: Node2D) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for impact in session._weapon_impacts:
			if bool(impact.get("critical_hit", false)):
				return true
	return false

func _verify_status_capture(session: Node2D) -> bool:
	var status_types := ["burn", "poison", "bleed", "chill", "shock"]
	var positions := [Vector2(-220.0, 70.0), Vector2(-110.0, 70.0), Vector2(0.0, 70.0),
		Vector2(110.0, 70.0), Vector2(220.0, 70.0)]
	var screen_positions: Array[Vector2] = []
	var entities: Array = []
	session._overcharge_shock_expires_at.clear()
	for index in status_types.size():
		var position: Vector2 = positions[index]
		screen_positions.append(session.get_global_transform_with_canvas() * position)
		entities.append({
			"id": {"index": index, "generation": 1},
			"components": {
				"EnemyType": "chaser",
				"Transform2D": {"x": position.x, "y": position.y},
			},
		})
	session._entities = entities
	session._sprite_renderer.set_entities(entities)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var baseline: Image = root.get_texture().get_image()
	for index in entities.size():
		var components: Dictionary = entities[index]["components"]
		match status_types[index]:
			"burn", "poison", "bleed":
				components["DamageOverTimeEffects"] = [{"status_type": status_types[index]}]
			"chill":
				components["Chill"] = {}
			"shock":
				var entity_id: Dictionary = entities[index]["id"]
				session._overcharge_shock_expires_at[
					session._entity_key(int(entity_id["index"]), int(entity_id["generation"]))
				] = session._last_simulation_time + 1.0
	session._entities = entities
	session._sprite_renderer.set_entities(entities)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var status_image: Image = root.get_texture().get_image()
	for index in status_types.size():
		var annulus: Vector2 = STATUS_RING_ANNULI[status_types[index]]
		var pixels := _count_annulus_differences(
				baseline, status_image, screen_positions[index], annulus.x, annulus.y)
		if pixels < 8:
			_fail("The %s status ring should render outside the enemy sprite" % status_types[index])
			return false
		print("%s status ring changed pixels: %d" % [status_types[index], pixels])
	if status_image.save_png("/tmp/dopamine-status-rings.png") != OK:
		_fail("Could not save the status ring visual capture")
		return false
	_settings.set_reduced_visual_effects_enabled(true)
	session.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var reduced_image: Image = root.get_texture().get_image()
	for index in status_types.size():
		var annulus: Vector2 = STATUS_RING_ANNULI[status_types[index]]
		if _count_annulus_differences(
				baseline, reduced_image, screen_positions[index], annulus.x, annulus.y) < 8:
			_settings.set_reduced_visual_effects_enabled(false)
			_fail("Reduced decorative effects should preserve the %s status ring" % status_types[index])
			return false
	_settings.set_reduced_visual_effects_enabled(false)
	session._entities = []
	session._sprite_renderer.set_entities([])
	return true

func _count_annulus_differences(baseline: Image, rendered: Image, center: Vector2,
		inner_radius: float, outer_radius: float) -> int:
	var changed := 0
	var outer_squared := outer_radius * outer_radius
	var inner_squared := inner_radius * inner_radius
	for y in range(maxi(0, int(center.y - outer_radius)), mini(rendered.get_height(), int(center.y + outer_radius + 1.0))):
		for x in range(maxi(0, int(center.x - outer_radius)), mini(rendered.get_width(), int(center.x + outer_radius + 1.0))):
			var offset := Vector2(x, y) - center
			if offset.length_squared() < inner_squared or offset.length_squared() > outer_squared:
				continue
			if not baseline.get_pixel(x, y).is_equal_approx(rendered.get_pixel(x, y)):
				changed += 1
	return changed

func _next_impact_random(session: Node2D, reduced: bool) -> float:
	_settings.set_reduced_visual_effects_enabled(reduced)
	session._sandbox_rng.seed = 7253
	session._sandbox_rng_log.clear()
	session._add_weapon_impact("inferno_sprayer", Vector2.ZERO, false)
	return session._random_float("visual_effect_random_stream_probe")

func _next_arc_random(session: Node2D, reduced: bool) -> float:
	_settings.set_reduced_visual_effects_enabled(reduced)
	session._sandbox_rng.seed = 8129
	session._sandbox_rng_log.clear()
	session._add_lightning_arc(Vector2.ZERO, Vector2.RIGHT * 20.0)
	return session._random_float("visual_effect_random_stream_probe")

func _fail(message: String) -> void:
	if _settings != null:
		_settings.set_reduced_visual_effects_enabled(false)
	push_error(message)
	quit(1)
