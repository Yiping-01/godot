extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export_file("*.tscn") var phase_two_scene := "res://demo/scenes/levels/demo_boss_phase_2.tscn"

var boss_active := false
var boss_ref: Node2D
var return_door: Area2D
var phase_two_transitioning := false


func _ready() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	return_door = get_node_or_null("ReturnDoor") as Area2D
	var wind := get_node_or_null("BossRoomWind") as AudioStreamPlayer
	if wind != null and wind.stream != null:
		wind.play()
	set_process(true)


func _process(_delta: float) -> void:
	if boss_active and (boss_ref == null or not is_instance_valid(boss_ref)):
		_complete_boss_fight()


func _exit_tree() -> void:
	var wind := get_node_or_null("BossRoomWind") as AudioStreamPlayer
	if wind != null:
		wind.stop()


func _on_demo_boss_intro_started(boss: Node) -> void:
	if boss_active:
		return
	boss_active = true
	boss_ref = boss as Node2D
	_set_return_door_locked(true)
	_focus_arena_audio(true)


func _complete_boss_fight() -> void:
	if phase_two_transitioning:
		return
	boss_active = false
	boss_ref = null
	_start_phase_two_transition()


func _start_phase_two_transition() -> void:
	phase_two_transitioning = true
	_set_return_door_locked(false)
	_focus_arena_audio(false)
	DEMO_COMBAT_JUICE.shake_camera(self, 1.05, 14.0)
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title("Boss Phase 2", "The arena opens")
	await get_tree().create_timer(1.15).timeout
	GameState.set_input_locked(false)
	get_tree().change_scene_to_file(phase_two_scene)


func _set_return_door_locked(locked: bool) -> void:
	if return_door == null:
		return
	return_door.set_deferred("monitoring", not locked)
	return_door.set_deferred("monitorable", not locked)
	var trace := return_door.get_node_or_null("GateTrace") as Line2D
	if trace != null:
		trace.default_color = Color(1.0, 0.42, 0.2, 0.78) if locked else Color(0.62, 0.9, 0.92, 0.58)
	var locked_shade := return_door.get_node_or_null("LockedShade") as CanvasItem
	if locked_shade != null:
		locked_shade.visible = locked
	var locked_label := return_door.get_node_or_null("LockedLabel") as CanvasItem
	if locked_label != null:
		locked_label.visible = locked
	var prompt_label := return_door.get_node_or_null("ReturnDoorPromptLabel") as CanvasItem
	if prompt_label != null:
		prompt_label.visible = not locked


func _focus_arena_audio(active: bool) -> void:
	var wind := get_node_or_null("BossRoomWind") as AudioStreamPlayer
	if wind == null:
		return
	var tween := create_tween()
	tween.tween_property(wind, "volume_db", -10.0 if active else -17.0, 0.55)
