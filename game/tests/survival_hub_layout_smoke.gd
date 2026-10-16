extends SceneTree

class ProfileStub:
	extends RefCounted
	func load_profile() -> Dictionary:
		return {"ok": true, "profile": {
			"highest_unlocked_difficulty": "hard",
			"armorless_records": {"easy": {"wave": 12, "survival_time_seconds": 300.0, "kills": 111}},
		}}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for size in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var hub: Control = load("res://scenes/survival_hub.tscn").instantiate()
		hub.progression_service = ProfileStub.new()
		viewport.add_child(hub)
		await process_frame
		await process_frame
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		var content := (hub.get_node("Content") as Control).get_global_rect()
		var left := (hub.get_node("Content/Main/DifficultyCard") as Control).get_global_rect()
		var difficulty_card := hub.get_node("Content/Main/DifficultyCard") as PanelContainer
		var preparation_card := hub.get_node("Content/Main/PreparationCard") as PanelContainer
		var right := preparation_card.get_global_rect()
		var launch := (hub.get_node("Content/Main/PreparationCard/Body/LaunchButton") as Control).get_global_rect()
		var records_button := (hub.get_node("Content/Header/RecordsButton") as Control).get_global_rect()
		var record_status := (hub.get_node("Content/Main/DifficultyCard/Body/ArmorlessRecordStatus") as Control).get_global_rect()
		var difficulty_style := difficulty_card.get_theme_stylebox("panel") as StyleBoxFlat
		var preparation_style := preparation_card.get_theme_stylebox("panel") as StyleBoxFlat
		if difficulty_style == null or difficulty_style.border_color.to_html(false) != "3d4868" or \
			preparation_style == null or preparation_style.border_color.to_html(false) != "37e8f5":
			_fail("Hub should keep difficulty secondary and highlight the preparation action surface")
			return
		if not bounds.encloses(content) or not bounds.encloses(left) or not bounds.encloses(right) or \
			not bounds.encloses(launch) or not bounds.encloses(records_button) or not left.encloses(record_status) or left.intersects(right):
			_fail("Hub layout should fit and keep columns separate at %s: left=%s right=%s launch=%s records=%s" % [size, left, right, launch, records_button])
			return
		var record_label: Label = hub.get_node("Content/Main/DifficultyCard/Body/ArmorlessRecordStatus")
		if not record_label.text.contains("WAVE 12") or record_label.text.find("111 KILLS") < 0:
			_fail("Armorless record summary should show real score fields at %s" % size)
			return
		var record_text_width: float = record_label.get_theme_font("font").get_string_size(
			record_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7
		).x
		if record_text_width > record_label.size.x:
			_fail("The Armorless record should fit without clipping at %s: text=%s control=%s" % [
				size, record_text_width, record_label.size.x,
			])
			return
		var records_button_node: Button = hub.get_node("Content/Header/RecordsButton")
		records_button_node.pressed.emit()
		await process_frame
		var records_panel := hub.get_node("ArmorlessRecordsPanel") as Control
		var records_rect := records_panel.get_node("Panel") as Control
		if not records_panel.visible or not bounds.encloses(records_rect.get_global_rect()):
			_fail("The records panel should fit within the viewport at %s" % size)
			return
		var records_list: VBoxContainer = records_panel.get_node("Panel/Content/RecordsScroll/Records")
		for row in records_list.get_children():
			var row_control := row as Control
			var row_text_width: float = row_control.get_theme_font("font").get_string_size(
				(row as Label).text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8
			).x
			if not records_rect.get_global_rect().encloses(row_control.get_global_rect()) or row_text_width > row_control.size.x:
				_fail("Records should remain inside the panel without clipping at %s" % size)
				return
		var capture_records: bool = size == Vector2i(640, 360) and "--capture-records" in OS.get_cmdline_user_args()
		if not capture_records:
			records_panel.visible = false
		if size == Vector2i(640, 360) and ("--capture" in OS.get_cmdline_user_args() or capture_records):
			await RenderingServer.frame_post_draw
			var capture_path := "/tmp/dopamine-survival-records.png" if capture_records else "/tmp/dopamine-survival-hub.png"
			if viewport.get_texture().get_image().save_png(capture_path) != OK:
				_fail("Could not capture the 640x360 Survival hub render: %s" % capture_path)
				return
		viewport.queue_free()
		await process_frame
	print("Survival hub fits 640x360, 1280x720 and 1920x1080 viewports")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
