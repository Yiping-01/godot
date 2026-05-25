extends Control

const LEVEL1_SCENE := "res://demo/scenes/levels/demo_level_1.tscn"
const TITLE_FONT_PATH := "res://demo/assets/hollow_import/fonts/TrajanPro-Regular.otf"
const BODY_FONT_PATH := "res://demo/assets/hollow_import/fonts/NotoSerifCJKsc-Regular.otf"
const TITLE_MUSIC_PATH := "res://demo/assets/audio/scores/bgtitle_music.wav"
const UI_CONFIRM_PATH := "res://demo/assets/audio/scores/jump.wav"

@onready var start_button: Button = $Menu/StartButton
@onready var continue_button: Button = $Menu/ContinueButton
@onready var language_zh_button: Button = $LanguagePanel/ChineseButton
@onready var language_en_button: Button = $LanguagePanel/EnglishButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var subtitle_label: Label = $SubtitleLabel
@onready var fade_rect: ColorRect = $FadeRect

var music_player: AudioStreamPlayer
var confirm_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var global_music := get_node_or_null("/root/MusicPlayer")
	if global_music != null and global_music.has_method("stop_game_music"):
		global_music.stop_game_music()
	_apply_fonts()
	_build_audio()
	_connect_button_feedback()
	start_button.pressed.connect(_start_new_flow)
	continue_button.pressed.connect(_continue_flow)
	language_zh_button.pressed.connect(_set_language.bind("zh"))
	language_en_button.pressed.connect(_set_language.bind("en"))
	quit_button.pressed.connect(Callable(get_tree(), "quit"))
	var localization := _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_update_texts"))
	continue_button.disabled = not GameState.has_continue_scene()
	_update_texts()
	_fade_in()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _start_new_flow() -> void:
	GameState.reset_demo_state()
	GameState.clear_continue_scene()
	GameState.set_input_locked(false)
	_load_scene(LEVEL1_SCENE)


func _continue_flow() -> void:
	GameState.set_input_locked(false)
	_load_scene(GameState.prepare_continue_scene())


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
