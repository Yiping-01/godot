extends Area2D
class_name HulobSceneTransition

@export_file("*.tscn") var target_scene := ""
@export var target_spawn_marker_name := ""
@export var require_interact := true
@export var transition_label := "傳送"
@export var loading_time := 0.18
@export var enabled := true

var triggered := false
var player_nearby: Node2D
var prompt_label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	for child in get_children():
		if child is Label:
			prompt_label = child
			prompt_label.text = transition_label
			prompt_label.visible = false
			break
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not require_interact or triggered or player_nearby == null:
		return
	if not event.is_action_pressed("interact"):
		return
	if GameState.input_locked:
		return

	get_viewport().set_input_as_handled()
	triggered = true
	_load_target_scene()


func _on_body_entered(body: Node2D) -> void:
	if triggered or not enabled or not body.is_in_group("player"):
		return

	player_nearby = body
	if require_interact:
		if prompt_label != null:
			prompt_label.visible = true
		var ui := get_tree().get_first_node_in_group("game_ui")
		if ui != null and ui.has_method("show_prompt"):
			ui.show_prompt("按 E " + transition_label)
		return

	triggered = true
	_load_target_scene()


func _on_body_exited(body: Node2D) -> void:
	if body != player_nearby:
		return

	player_nearby = null
	if prompt_label != null:
		prompt_label.visible = false
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_prompt"):
		ui.hide_prompt()


func _load_target_scene() -> void:
	if target_scene == "":
		triggered = false
		return

	if prompt_label != null:
		prompt_label.visible = false
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_prompt"):
		ui.hide_prompt()
	if ui != null and ui.has_method("close_all_windows"):
		ui.close_all_windows()

	GameState.set_input_locked(true)

	if target_spawn_marker_name != "":
		GameState.set_pending_spawn_marker(target_spawn_marker_name)
		GameState.save_continue_scene(target_scene, Vector2.ZERO, false, target_spawn_marker_name)
	else:
		GameState.save_continue_scene(target_scene)
	GameState.save_game()

	GameState.set_input_locked(false)
	var loader := HulobLoadingTransition.new()
	get_tree().root.add_child(loader)
	await loader.load_scene(target_scene, maxf(loading_time, 0.45))
