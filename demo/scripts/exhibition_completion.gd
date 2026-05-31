extends Node

const LEADERBOARD_PATH := "user://leaderboard.cfg"
const MAIN_MENU_SCENE := "res://demo/scenes/levels/demo_main_menu.tscn"
const PURIFIED_EPILOGUE_SCENE := "res://demo/scenes/levels/demo_purified_epilogue.tscn"
const MAX_LEADERBOARD_ENTRIES := 10

var completion_layer: CanvasLayer
var name_input: LineEdit
var leaderboard_label: Label
var submit_button: Button
var continue_button: Button
var return_button: Button
var final_time_seconds := 0
var final_death_count := 0
var score_submitted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_nodes")


func _connect_existing_nodes() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		for node in scene.find_children("*", "Node", true, false):
			_try_connect_boss_manager(node)


func _on_node_added(node: Node) -> void:
	_try_connect_boss_manager(node)


func _try_connect_boss_manager(node: Node) -> void:
	if node == null or not is_instance_valid(node) or not node.has_signal("boss_defeated"):
		return
	var callback := Callable(self, "_on_boss_defeated")
	if not node.is_connected("boss_defeated", callback):
		node.connect("boss_defeated", callback)


func _on_boss_defeated() -> void:
	if completion_layer != null and is_instance_valid(completion_layer):
		return
	final_time_seconds = GameState.get_run_elapsed_seconds()
	final_death_count = GameState.player_death_count
	GameState.mark_region_purified()
	GameState.set_input_locked(true)
	_build_completion_overlay()


func _build_completion_overlay() -> void:
	completion_layer = CanvasLayer.new()
	completion_layer.name = "ExhibitionCompletion"
	completion_layer.layer = 180
	completion_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(completion_layer)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.018, 0.024, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	completion_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -360.0
	panel.offset_top = -370.0
	panel.offset_right = 360.0
	panel.offset_bottom = 370.0
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	completion_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	content.add_child(_make_label("海溝已淨化", 42, Color(0.78, 1.0, 0.96, 1.0)))
	content.add_child(_make_label("潮流重新恢復清澈。留下你的名字，讓這次潛行被記錄下來。", 20, Color(0.82, 0.92, 0.94, 0.94)))

	var stats := _make_label("完成時間  %s\n死亡次數  %d" % [_format_time(final_time_seconds), final_death_count], 26, Color(1.0, 0.9, 0.58, 1.0))
	stats.add_theme_constant_override("line_spacing", 8)
	content.add_child(stats)

	name_input = LineEdit.new()
	name_input.placeholder_text = "輸入玩家名稱"
	name_input.max_length = 16
	name_input.custom_minimum_size = Vector2(0.0, 52.0)
	name_input.add_theme_font_size_override("font_size", 22)
	name_input.add_theme_stylebox_override("normal", _make_input_style(false))
	name_input.add_theme_stylebox_override("focus", _make_input_style(true))
	name_input.text_submitted.connect(_on_name_submitted)
	content.add_child(name_input)

	submit_button = _make_button("登錄排行榜")
	submit_button.pressed.connect(_submit_score)
	content.add_child(submit_button)

	leaderboard_label = _make_label("", 19, Color(0.84, 0.96, 0.98, 0.96))
	leaderboard_label.custom_minimum_size = Vector2(0.0, 244.0)
	content.add_child(leaderboard_label)

	var completion_actions := HBoxContainer.new()
	completion_actions.add_theme_constant_override("separation", 12)
	content.add_child(completion_actions)

	continue_button = _make_button("繼續遊戲")
	continue_button.visible = false
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.pressed.connect(_continue_game)
	completion_actions.add_child(continue_button)

	return_button = _make_button("返回主選單")
	return_button.visible = false
	return_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return_button.pressed.connect(_return_to_main_menu)
	completion_actions.add_child(return_button)

	_refresh_leaderboard()
	name_input.grab_focus()


func _on_name_submitted(_text: String) -> void:
	_submit_score()


func _submit_score() -> void:
	if score_submitted:
		return
	score_submitted = true
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "旅人"
	_add_leaderboard_entry(player_name, final_time_seconds, final_death_count)
	name_input.editable = false
	submit_button.disabled = true
	submit_button.text = "已登錄"
	continue_button.visible = true
	return_button.visible = true
	_refresh_leaderboard()
	continue_button.grab_focus()


func _continue_game() -> void:
	GameState.set_pending_spawn_marker("purified_entry")
	_close_completion_overlay()
	get_tree().change_scene_to_file(PURIFIED_EPILOGUE_SCENE)


func _return_to_main_menu() -> void:
	_close_completion_overlay()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _close_completion_overlay() -> void:
	GameState.set_input_locked(false)
	if completion_layer != null and is_instance_valid(completion_layer):
		completion_layer.queue_free()
	completion_layer = null
	score_submitted = false


func get_leaderboard_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var config := ConfigFile.new()
	if config.load(LEADERBOARD_PATH) != OK:
		return entries
	var stored: Variant = config.get_value("leaderboard", "entries", [])
	if not stored is Array:
		return entries
	for value in stored:
		if value is Dictionary:
			entries.append((value as Dictionary).duplicate(true))
	_sort_entries(entries)
	return entries


func _add_leaderboard_entry(player_name: String, time_seconds: int, deaths: int) -> void:
	var entries := get_leaderboard_entries()
	entries.append({
		"name": player_name,
		"time_seconds": maxi(0, time_seconds),
		"deaths": maxi(0, deaths),
		"completed_at": Time.get_datetime_string_from_system(false, true),
	})
	_sort_entries(entries)
	if entries.size() > MAX_LEADERBOARD_ENTRIES:
		entries.resize(MAX_LEADERBOARD_ENTRIES)
	var config := ConfigFile.new()
	config.set_value("leaderboard", "entries", entries)
	config.save(LEADERBOARD_PATH)


func _sort_entries(entries: Array[Dictionary]) -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_time := int(a.get("time_seconds", 0))
		var b_time := int(b.get("time_seconds", 0))
		if a_time != b_time:
			return a_time < b_time
		return int(a.get("deaths", 0)) < int(b.get("deaths", 0))
	)


func _refresh_leaderboard() -> void:
	if leaderboard_label == null:
		return
	var lines: Array[String] = ["排行榜"]
	var entries := get_leaderboard_entries()
	if entries.is_empty():
		lines.append("尚未有完成紀錄")
	else:
		for index in range(entries.size()):
			var entry := entries[index]
			lines.append("%02d  %-16s  %s  死亡 %d" % [
				index + 1,
				String(entry.get("name", "旅人")).left(16),
				_format_time(int(entry.get("time_seconds", 0))),
				int(entry.get("deaths", 0)),
			])
	leaderboard_label.text = "\n".join(lines)


func _format_time(total_seconds: int) -> String:
	var seconds := maxi(0, total_seconds)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_stylebox_override("normal", _make_button_style(false))
	button.add_theme_stylebox_override("hover", _make_button_style(true))
	button.add_theme_stylebox_override("focus", _make_button_style(true))
	button.add_theme_stylebox_override("pressed", _make_button_style(true))
	return button


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.045, 0.055, 0.97)
	style.border_color = Color(0.54, 0.9, 0.88, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style


func _make_input_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.075, 0.09, 0.96)
	style.border_color = Color(1.0, 0.82, 0.34, 0.94) if focused else Color(0.48, 0.82, 0.82, 0.62)
	style.set_border_width_all(2 if focused else 1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


func _make_button_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.16, 0.96) if focused else Color(0.025, 0.08, 0.09, 0.9)
	style.border_color = Color(1.0, 0.82, 0.34, 0.9) if focused else Color(0.48, 0.78, 0.78, 0.56)
	style.set_border_width_all(2 if focused else 1)
	style.set_corner_radius_all(4)
	return style
