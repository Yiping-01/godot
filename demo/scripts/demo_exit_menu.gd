extends CanvasLayer
class_name DemoExitMenu

@export_file("*.tscn") var main_menu_scene := "res://demo/scenes/levels/demo_main_menu.tscn"

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const DEMO_MENU_UI_ART := preload("res://demo/scripts/demo_menu_ui_art.gd")

var pause_dim: ColorRect
var pause_panel: Panel
var audio_panel: Panel
var language_panel: Panel
var controls_panel: Panel

var resume_button: Button
var audio_button: Button
var language_button: Button
var controls_button: Button
var menu_button: Button

var music_label: Label
var sfx_label: Label
var music_slider: HSlider
var sfx_slider: HSlider
var zh_button: Button
var en_button: Button
var waiting_label: Label
var reset_controls_button: Button
var controls_back_button: Button
var audio_back_button: Button
var language_back_button: Button

var key_buttons: Dictionary = {}
var key_action_labels: Dictionary = {}
var waiting_for_action := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_build_pause_menu()
	_build_audio_panel()
	_build_language_panel()
	_build_controls_panel()
	_hide_all()
	var settings := _get_input_settings()
	if settings != null:
		settings.connect("controls_changed", Callable(self, "_refresh_key_labels"))
	var localization := _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_texts"))
	_update_texts()
	_refresh_key_labels()


func _input(event: InputEvent) -> void:
	if waiting_for_action != "":
		_capture_rebind_input(event)
		return

	if event.is_action_pressed("ui_cancel"):
		if _is_sub_panel_open():
			_show_pause_panel()
		elif pause_panel.visible:
			_hide_all()
		elif _close_game_ui_window():
			pass
		else:
			_show_pause_panel()
		get_viewport().set_input_as_handled()


func _capture_rebind_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		waiting_for_action = ""
		waiting_label.text = _tr("Cancelled.", "已取消。")
		return

	var action := waiting_for_action
	waiting_for_action = ""
	var settings := _get_input_settings()
	var result := ERR_UNAVAILABLE
	if settings != null:
		result = settings.call("rebind_keyboard_action", action, event) as Error
	waiting_label.text = _tr("Key changed.", "按鍵已更新。") if result == OK else _tr("This key cannot be used.", "這個按鍵無法使用。")
	_refresh_key_labels()


func _build_pause_menu() -> void:
	pause_dim = ColorRect.new()
	pause_dim.name = "PauseDim"
	pause_dim.color = Color(0.0, 0.0, 0.0, 0.62)
	pause_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_dim)

	pause_panel = _create_panel("PausePanel", Vector2(460.0, 560.0))
	var content := _panel_content(pause_panel, "MenuContent", 34.0, 34.0)
	content.add_child(_title_label("PAUSED"))
	content.add_child(_hint_label(_tr("Esc closes the menu", "Esc 關閉選單")))

	resume_button = _menu_button("")
	audio_button = _menu_button("")
	language_button = _menu_button("")
	controls_button = _menu_button("")
	menu_button = _menu_button("")
	for button in [resume_button, audio_button, language_button, controls_button, menu_button]:
		content.add_child(button)

	resume_button.pressed.connect(_hide_all)
	audio_button.pressed.connect(_show_audio_panel)
	language_button.pressed.connect(_show_language_panel)
	controls_button.pressed.connect(_show_controls_panel)
	menu_button.pressed.connect(_go_to_main_menu)


func _build_audio_panel() -> void:
	audio_panel = _create_panel("AudioPanel", Vector2(620.0, 420.0))
	var content := _panel_content(audio_panel, "AudioContent", 34.0, 34.0)
	content.add_child(_title_label(_tr("Audio", "音效")))
	content.add_child(_hint_label(_tr("Adjust music and sound effects separately.", "分開調整音樂與遊戲音效。")))

	music_label = _section_label("")
	content.add_child(music_label)
	music_slider = _volume_slider(_bus_volume(MUSIC_BUS))
	music_slider.value_changed.connect(_on_music_volume_changed)
	content.add_child(music_slider)

	sfx_label = _section_label("")
	content.add_child(sfx_label)
	sfx_slider = _volume_slider(_bus_volume(SFX_BUS))
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	content.add_child(sfx_slider)

	audio_back_button = _secondary_button("")
	audio_back_button.pressed.connect(_show_pause_panel)
	content.add_child(_centered_row([audio_back_button]))


func _build_language_panel() -> void:
	language_panel = _create_panel("LanguagePanel", Vector2(620.0, 360.0))
	var content := _panel_content(language_panel, "LanguageContent", 34.0, 34.0)
	content.add_child(_title_label(_tr("Language", "語言")))
	content.add_child(_hint_label(_tr("Choose the display language.", "選擇遊戲介面的顯示語言。")))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	zh_button = _menu_button("中文")
	en_button = _menu_button("English")
	zh_button.custom_minimum_size = Vector2(210.0, 58.0)
	en_button.custom_minimum_size = Vector2(210.0, 58.0)
	zh_button.pressed.connect(_set_language.bind("zh"))
	en_button.pressed.connect(_set_language.bind("en"))
	row.add_child(zh_button)
	row.add_child(en_button)

	language_back_button = _secondary_button("")
	language_back_button.pressed.connect(_show_pause_panel)
	content.add_child(_centered_row([language_back_button]))


func _build_controls_panel() -> void:
	controls_panel = _create_panel("ControlsPanel", Vector2(1040.0, 760.0))
	var content := _panel_content(controls_panel, "ControlsContent", 32.0, 28.0)
	content.add_child(_title_label(_tr("Controls", "按鍵")))
	waiting_label = _hint_label("")
	content.add_child(waiting_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 560.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 28)
	scroll.add_child(columns)

	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	left.custom_minimum_size = Vector2(470.0, 0.0)
	right.custom_minimum_size = Vector2(470.0, 0.0)
	left.add_theme_constant_override("separation", 8)
	right.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	columns.add_child(right)

	var settings := _get_input_settings()
	var actions: Array = [] if settings == null else settings.call("get_actions")
	var split_index := int(ceil(float(actions.size()) * 0.5))
	for i in range(actions.size()):
		var target: VBoxContainer = left if i < split_index else right
		_add_key_row(target, String(actions[i]["action"]))

	reset_controls_button = _secondary_button("")
	controls_back_button = _secondary_button("")
	reset_controls_button.pressed.connect(_reset_controls)
	controls_back_button.pressed.connect(_show_pause_panel)
	content.add_child(_centered_row([reset_controls_button, controls_back_button]))


func _add_key_row(parent: VBoxContainer, action_name: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(450.0, 44.0)
	row.add_theme_constant_override("separation", 12)
	row.add_theme_stylebox_override("panel", _button_style(Color(0.025, 0.045, 0.055, 0.42), Color(0.32, 0.52, 0.56, 0.18)))
	parent.add_child(row)

	var label := Label.new()
	label.custom_minimum_size = Vector2(280.0, 42.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0, 0.92))
	row.add_child(label)
	key_action_labels[action_name] = label

	var button := _secondary_button("")
	button.custom_minimum_size = Vector2(130.0, 38.0)
	button.pressed.connect(_start_rebind.bind(action_name))
	row.add_child(button)
	key_buttons[action_name] = button


func _show_pause_panel() -> void:
	GameState.set_input_locked(true)
	pause_dim.show()
	pause_panel.show()
	audio_panel.hide()
	language_panel.hide()
	controls_panel.hide()
	get_tree().paused = true
	waiting_for_action = ""
	resume_button.grab_focus()


func _show_audio_panel() -> void:
	_show_sub_panel(audio_panel)
	audio_back_button.grab_focus()


func _show_language_panel() -> void:
	_show_sub_panel(language_panel)
	_update_language_buttons()
	zh_button.grab_focus()


func _show_controls_panel() -> void:
	_show_sub_panel(controls_panel)
	waiting_for_action = ""
	waiting_label.text = _tr("Select a row, press a new key. Esc returns.", "選擇一列後按新的按鍵，Esc 返回。")
	_refresh_key_labels()
	controls_back_button.grab_focus()


func _show_sub_panel(panel: Panel) -> void:
	pause_dim.show()
	pause_panel.hide()
	audio_panel.hide()
	language_panel.hide()
	controls_panel.hide()
	panel.show()
	get_tree().paused = true


func _hide_all() -> void:
	waiting_for_action = ""
	pause_dim.hide()
	pause_panel.hide()
	audio_panel.hide()
	language_panel.hide()
	controls_panel.hide()
	get_tree().paused = false
	GameState.set_input_locked(false)


func _is_sub_panel_open() -> bool:
	return audio_panel.visible or language_panel.visible or controls_panel.visible


func _close_game_ui_window() -> bool:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui == null or not ui.has_method("has_open_window") or not ui.has_method("close_all_windows"):
		return false
	if not ui.has_open_window():
		return false
	ui.close_all_windows()
	return true


func _go_to_main_menu() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	GameState.save_game()
	get_tree().change_scene_to_file(main_menu_scene)


func _start_rebind(action_name: String) -> void:
	waiting_for_action = action_name
	waiting_label.text = _tr("Press a new key for %s. Esc cancels.", "請按下「%s」的新按鍵，Esc 取消。") % _action_label(action_name)


func _reset_controls() -> void:
	var settings := _get_input_settings()
	if settings != null:
		settings.call("reset_to_defaults")
	waiting_label.text = _tr("Controls reset.", "按鍵已重設。")
	_refresh_key_labels()


func _set_language(locale: String) -> void:
	var localization := _get_localization()
	if localization != null and localization.has_method("set_locale"):
		localization.call("set_locale", locale)
	_update_texts()
	_update_language_buttons()


func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume(MUSIC_BUS, value / 100.0)
	_update_texts()


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume(SFX_BUS, value / 100.0)
	_update_texts()


func _update_texts() -> void:
	resume_button.text = _tr("Resume", "繼續")
	audio_button.text = _tr("Audio", "音效")
	language_button.text = _tr("Language", "語言")
	controls_button.text = _tr("Controls", "按鍵")
	menu_button.text = _tr("Return to Main Menu", "返回主選單")

	music_label.text = _tr("Music: %d%%", "音樂：%d%%") % roundi(music_slider.value)
	sfx_label.text = _tr("SFX: %d%%", "音效：%d%%") % roundi(sfx_slider.value)
	audio_back_button.text = _tr("Back", "返回")
	language_back_button.text = _tr("Back", "返回")
	reset_controls_button.text = _tr("Reset", "重設")
	controls_back_button.text = _tr("Back", "返回")

	_update_language_buttons()
	_refresh_key_labels()


func _update_language_buttons() -> void:
	if zh_button == null or en_button == null:
		return
	var is_en := _is_en()
	_apply_selected_button(zh_button, not is_en)
	_apply_selected_button(en_button, is_en)


func _refresh_key_labels() -> void:
	var settings := _get_input_settings()
	for action_name in key_buttons.keys():
		var button := key_buttons[action_name] as Button
		if settings != null:
			button.text = String(settings.call("get_label_for_action", String(action_name)))
	for action_name in key_action_labels.keys():
		var label := key_action_labels[action_name] as Label
		label.text = _action_label(String(action_name))


func _action_label(action_name: String) -> String:
	var labels := {
		"move_up": ["Up", "向上"],
		"move_down": ["Down", "向下"],
		"move_left": ["Left", "向左"],
		"move_right": ["Right", "向右"],
		"jump": ["Jump", "跳躍"],
		"attack": ["Attack", "攻擊"],
		"dash": ["Dash", "衝刺"],
		"far_attack": ["Water Shot", "水槍"],
		"skill_group_switch": ["Skill Set Switch", "切換技能組"],
		"interact": ["Interact / Potion", "互動 / 血瓶"],
		"map": ["Map", "地圖"],
		"inventory": ["Inventory", "背包"],
		"audio_settings": ["Audio Menu", "音效選單"],
	}
	var pair: Array = labels.get(action_name, [action_name, action_name])
	return String(pair[0] if _is_en() else pair[1])


func _tr(en: String, zh: String) -> String:
	return en if _is_en() else zh


func _is_en() -> bool:
	var localization := _get_localization()
	return localization != null and String(localization.get("current_locale")) == "en"


func _get_input_settings() -> Node:
	return get_node_or_null("/root/InputSettings")


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _bus_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 100.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return clampf(round(db_to_linear(AudioServer.get_bus_volume_db(index)) * 100.0), 0.0, 100.0)


func _set_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))
	AudioServer.set_bus_mute(index, volume <= 0.0)


func _volume_slider(value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0.0, 42.0)
	return slider


func _create_panel(panel_name: String, size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = panel_name
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -size.x * 0.5
	panel.offset_top = -size.y * 0.5
	panel.offset_right = size.x * 0.5
	panel.offset_bottom = size.y * 0.5
	var panel_kind := "pause" if panel_name == "PausePanel" else "settings"
	panel.add_theme_stylebox_override("panel", DEMO_MENU_UI_ART.panel_style(panel_kind))
	add_child(panel)
	return panel


func _panel_content(panel: Panel, content_name: String, x_margin: float, y_margin: float) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.name = content_name
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = x_margin
	content.offset_top = y_margin
	content.offset_right = -x_margin
	content.offset_bottom = -y_margin
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	return content


func _title_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.9, 0.99, 1.0, 0.96))
	return label


func _hint_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.88, 0.82))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 0.94))
	return label


func _centered_row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	for item in buttons:
		row.add_child(item)
	return row


func _menu_button(text: String) -> Button:
	var button := _secondary_button(text)
	button.custom_minimum_size = Vector2(0.0, 58.0)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _secondary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150.0, 42.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 0.94))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.55, 1.0))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.04, 0.06, 0.78))
	button.add_theme_stylebox_override("normal", DEMO_MENU_UI_ART.small_button_style("normal"))
	button.add_theme_stylebox_override("hover", DEMO_MENU_UI_ART.small_button_style("hover"))
	button.add_theme_stylebox_override("focus", DEMO_MENU_UI_ART.small_button_style("focus"))
	button.add_theme_stylebox_override("pressed", DEMO_MENU_UI_ART.small_button_style("pressed"))
	return button


func _apply_selected_button(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", DEMO_MENU_UI_ART.small_button_style("pressed" if selected else "normal"))


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _button_style(fill, border)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
