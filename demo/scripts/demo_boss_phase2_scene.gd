extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export var phase_path: NodePath
@export var return_door_path: NodePath

var phase: Node
var return_door: Area2D


func _ready() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	phase = get_node_or_null(phase_path)
	return_door = get_node_or_null(return_door_path) as Area2D
	_set_return_door_locked(true)
	if phase != null and phase.has_signal("phase_finished"):
		phase.connect("phase_finished", Callable(self, "_on_phase_finished"))
	call_deferred("_start_phase")


func _start_phase() -> void:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title("Boss Phase 2", "Break the tentacles, then strike the core")
	if phase != null and phase.has_method("start_phase"):
		phase.call("start_phase")


func _on_phase_finished() -> void:
	_set_return_door_locked(false)
	DEMO_COMBAT_JUICE.shake_camera(self, 0.75, 12.0)
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title("Core Broken", "Return path opened")


func _set_return_door_locked(locked: bool) -> void:
	if return_door == null:
		return
	return_door.set_deferred("monitoring", not locked)
	return_door.set_deferred("monitorable", not locked)
	var locked_shade := return_door.get_node_or_null("LockedShade") as CanvasItem
	if locked_shade != null:
		locked_shade.visible = locked
	var prompt_label := return_door.get_node_or_null("ReturnDoorPromptLabel") as CanvasItem
	if prompt_label != null:
		prompt_label.visible = not locked
