extends Area2D
class_name TutorialTrigger

@export_multiline var tutorial_text := "教學提示"
@export var enabled := true
@export var display_time := 2.8
@export var one_shot := true
@export var hide_when_exit := true

var triggered := false


func _ready() -> void:
	match name:
		"MoveTutorial":
			tutorial_text = "按 A / D 左右移動，按 Z 跳躍。"
			display_time = maxf(display_time, 4.0)
		"WallTutorial":
			tutorial_text = "靠近牆面時按 Z 可以牆跳，按 C 可以衝刺。"
			display_time = maxf(display_time, 4.0)
		"WaterTutorial":
			tutorial_text = "進入水中後用方向鍵或 A / D 移動，按 F 發射水槍。"
			display_time = maxf(display_time, 4.0)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if not is_visible_in_tree():
		return
	if one_shot and triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		if ui.has_method("is_area_title_visible"):
			while is_inside_tree() and ui != null and is_instance_valid(ui) and ui.is_area_title_visible():
				var tree := get_tree()
				if tree == null:
					return
				await tree.process_frame
		if not is_inside_tree() or ui == null or not is_instance_valid(ui):
			return
		ui.show_tutorial(tutorial_text, display_time)


func _on_body_exited(body: Node2D) -> void:
	if not hide_when_exit or not body.is_in_group("player"):
		return

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_tutorial"):
		ui.hide_tutorial()
