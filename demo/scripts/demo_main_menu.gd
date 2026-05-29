extends Control

const LEVEL1_SCENE := "res://demo/scenes/levels/demo_level_1.tscn"
const TITLE_FONT_PATH := "res://demo/assets/hollow_import/fonts/TrajanPro-Regular.otf"
const BODY_FONT_PATH := "res://demo/assets/hollow_import/fonts/NotoSerifCJKsc-Regular.otf"
const TITLE_MUSIC_PATH := "res://demo/assets/audio/scores/bgtitle_music.wav"
const UI_CONFIRM_PATH := "res://demo/assets/audio/scores/jump.wav"
const DEMO_MENU_UI_ART := preload("res://demo/scripts/demo_menu_ui_art.gd")

@onready var start_button: Button = $Menu/StartButton
@onready var continue_button: Button = $Menu/ContinueButton
@onready var language_zh_button: Button = $LanguagePanel/ChineseButton
@onready var language_en_button: Button = $LanguagePanel/EnglishButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var subtitle_label: Label = $SubtitleLabel
@onready var fade_rect: ColorRect = $FadeRect
@onready var overwrite_save_dialog: ConfirmationDialog = $OverwriteSaveDialog
@onready var no_save_dialog: AcceptDialog = $NoSaveDialog
@onready var continue_info_panel: PanelContainer = $ContinueInfoPanel
@onready var save_preview_label: Label = $ContinueInfoPanel/Margin/Content/PreviewPanel/PreviewNameLabel
@onready var save_info_label: Label = $ContinueInfoPanel/Margin/Content/SaveInfoLabel
@onready var continue_load_button: Button = $ContinueInfoPanel/Margin/Content/ButtonRow/ContinueLoadButton
@onready var continue_cancel_button: Button = $ContinueInfoPanel/Margin/Content/ButtonRow/ContinueCancelButton

var music_player: AudioStreamPlayer
var confirm_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var global_music := get_node_or_null("/root/MusicPlayer")
	if global_music != null and global_music.has_method("stop_game_music"):
		global_music.stop_game_music()
	_apply_fonts()
	_apply_menu_ui_art()
	_build_audio()
	_connect_button_feedback()
	start_button.pressed.connect(_start_new_flow)
	continue_button.pressed.connect(_continue_flow)
	language_zh_button.pressed.connect(_set_language.bind("zh"))
	language_en_button.pressed.connect(_set_language.bind("en"))
	quit_button.pressed.connect(Callable(get_tree(), "quit"))
	overwrite_save_dialog.confirmed.connect(_confirm_new_game_overwrite)
	continue_load_button.pressed.connect(_confirm_continue_game)
	continue_cancel_button.pressed.connect(_hide_continue_info_panel)
	var localization := _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_texts"))
	continue_button.disabled = false
	continue_info_panel.hide()
	_update_texts()
	_fade_in()


func _apply_menu_ui_art() -> void:
	for button in [start_button, continue_button, quit_button]:
		_apply_button_art(button, false)
	for button in [language_zh_button, language_en_button, continue_load_button, continue_cancel_button]:
		_apply_button_art(button, true)
	if continue_info_panel != null:
		continue_info_panel.add_theme_stylebox_override("panel", DEMO_MENU_UI_ART.panel_style("save"))


func _apply_button_art(button: Button, small: bool) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 0.98))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.55, 1.0))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.04, 0.06, 0.78))
	if small:
		button.add_theme_stylebox_override("normal", DEMO_MENU_UI_ART.small_button_style("normal"))
		button.add_theme_stylebox_override("hover", DEMO_MENU_UI_ART.small_button_style("hover"))
		button.add_theme_stylebox_override("pressed", DEMO_MENU_UI_ART.small_button_style("pressed"))
		button.add_theme_stylebox_override("focus", DEMO_MENU_UI_ART.small_button_style("focus"))
	else:
		button.add_theme_stylebox_override("normal", DEMO_MENU_UI_ART.main_button_style("normal"))
		button.add_theme_stylebox_override("hover", DEMO_MENU_UI_ART.main_button_style("hover"))
		button.add_theme_stylebox_override("pressed", DEMO_MENU_UI_ART.main_button_style("pressed"))
		button.add_theme_stylebox_override("focus", DEMO_MENU_UI_ART.main_button_style("focus"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if continue_info_panel.visible:
			_hide_continue_info_panel()
			return
		get_tree().quit()


func _start_new_flow() -> void:
	if GameState.has_save_file():
		overwrite_save_dialog.popup_centered()
		return
	_start_new_game()


func _confirm_new_game_overwrite() -> void:
	_start_new_game()


func _start_new_game() -> void:
	_load_scene(GameState.start_new_game())


func _continue_flow() -> void:
	if not GameState.has_save_file():
		no_save_dialog.popup_centered()
		return
	_show_continue_info_panel()


func _show_continue_info_panel() -> void:
	var save_info := GameState.get_save_info()
	if save_info.is_empty():
		no_save_dialog.popup_centered()
		return

	var preview_scene_name := String(save_info.get("preview_scene_name", "未知地點"))
	save_preview_label.text = preview_scene_name
	save_info_label.text = "上次地點：%s\n錢幣：%d\n存檔時間：%s" % [
		preview_scene_name,
		int(save_info.get("coins", 0)),
		String(save_info.get("saved_at", "未知")),
	]
	continue_info_panel.show()


func _hide_continue_info_panel() -> void:
	continue_info_panel.hide()


func _confirm_continue_game() -> void:
	_hide_continue_info_panel()
	_load_scene(GameState.continue_game())


func _load_scene(path: String) -> void:
	_play_confirm()
	var loader := DemoLoadingTransition.new()
	get_tree().root.add_child(loader)
	await loader.load_scene(path, 0.55)


func _fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var tween := fade_rect.create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.65)


func _set_language(locale: String) -> void:
	var localization := _get_localization()
	if localization != null and localization.has_method("set_locale"):
		localization.call("set_locale", locale)
	_update_texts()


func _update_texts() -> void:
	var localization := _get_localization()
	var is_en := localization != null and String(localization.get("current_locale")) == "en"
	subtitle_label.text = ""
	start_button.text = "Start" if is_en else "開始"
	continue_button.text = "Continue" if is_en else "繼續"
	quit_button.text = "Quit" if is_en else "結束"
	language_zh_button.text = "中文"
	language_en_button.text = "English"


func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "TitleMusic"
	music_player.stream = load(TITLE_MUSIC_PATH)
	music_player.bus = "Music"
	music_player.volume_db = -8.0
	music_player.autoplay = true
	add_child(music_player)
	music_player.play()

	confirm_player = AudioStreamPlayer.new()
	confirm_player.name = "MenuConfirm"
	confirm_player.stream = load(UI_CONFIRM_PATH)
	confirm_player.bus = "SFX"
	add_child(confirm_player)


func _connect_button_feedback() -> void:
	for button in [start_button, continue_button, quit_button, language_zh_button, language_en_button]:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.focus_entered.connect(_on_button_hovered.bind(button))
		button.pressed.connect(_animate_button_press.bind(button))


func _on_button_hovered(button: Button) -> void:
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * 1.025, 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.14)


func _animate_button_press(button: Button) -> void:
	_play_confirm()
	var tween := button.create_tween()
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 0.62), 0.06)
	tween.tween_property(button, "modulate", Color.WHITE, 0.16)


func _play_confirm() -> void:
	if confirm_player != null and confirm_player.stream != null:
		confirm_player.play()


func _apply_fonts() -> void:
	var body_font := load(BODY_FONT_PATH)
	if body_font is Font:
		_apply_font_to_control_tree(self, body_font)




func _apply_font_to_control_tree(control: Control, font: Font) -> void:
	control.add_theme_font_override("font", font)
	for child in control.get_children():
		if child is Control:
			_apply_font_to_control_tree(child, font)


func _text(key: String, en: String, zh: String) -> String:
	var localization := _get_localization()
	if localization != null and String(localization.get("current_locale")) != "en" and key.begins_with("DEMO_"):
		return zh
	if localization != null and localization.has_method("text"):
		var localized := String(localization.call("text", key))
		if localized != "" and localized != key:
			return localized
	if localization != null and String(localization.get("current_locale")) == "en":
		return en
	return zh


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")
