extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export var entry_shake_duration := 0.58
@export var entry_shake_strength := 13.5


func _ready() -> void:
	_play_boss_music()
	_play_entry_impact()
	_show_pending_transition_title()


func _play_entry_impact() -> void:
	var shake := GameState.consume_pending_transition_shake()
	var duration := float(shake.get("duration", 0.0))
	var strength := float(shake.get("strength", 0.0))
	if duration <= 0.0 or strength <= 0.0:
		duration = entry_shake_duration
		strength = entry_shake_strength
	DEMO_COMBAT_JUICE.shake_camera(self, duration, strength)


func _show_pending_transition_title() -> void:
	var title_data: Dictionary = GameState.consume_pending_transition_title()
	var main_title := String(title_data.get("title", ""))
	var sub_title := String(title_data.get("subtitle", ""))
	if main_title.is_empty() and sub_title.is_empty():
		return

	var layer := CanvasLayer.new()
	layer.name = "PhaseTwoTransitionTitle"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var text_box := VBoxContainer.new()
	text_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	text_box.offset_left = -520.0
	text_box.offset_top = 70.0
	text_box.offset_right = 520.0
	text_box.offset_bottom = 180.0
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_theme_constant_override("separation", 8)
	root.add_child(text_box)

	var main_label := Label.new()
	main_label.text = main_title
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 34)
	main_label.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	main_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	main_label.add_theme_constant_override("shadow_offset_x", 3)
	main_label.add_theme_constant_override("shadow_offset_y", 3)
	text_box.add_child(main_label)

	var sub_label := Label.new()
	sub_label.text = sub_title
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 25)
	sub_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.72, 1.0))
	sub_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	sub_label.add_theme_constant_override("shadow_offset_x", 3)
	sub_label.add_theme_constant_override("shadow_offset_y", 3)
	text_box.add_child(sub_label)

	text_box.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(text_box, "modulate:a", 1.0, 0.22)
	tween.tween_interval(2.45)
	tween.tween_property(text_box, "modulate:a", 0.0, 0.45)
	tween.tween_callback(layer.queue_free)


func _play_boss_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_boss_music"):
		music_player.play_boss_music()
