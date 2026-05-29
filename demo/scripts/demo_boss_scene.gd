extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export_file("*.tscn") var phase_two_scene := "res://demo/scenes/levels/demo_boss_phase_2.tscn"
@export var phase_two_transition_delay := 0.16
@export var phase_two_transition_shake_duration := 0.95
@export var phase_two_transition_shake_strength := 42.0
@export var phase_two_entry_shake_min_duration := 0.58

var boss_active := false
var boss_ref: Node2D
var return_door: Area2D
var phase_two_transitioning := false
var phase_two_packed_scene: PackedScene


func _ready() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	return_door = get_node_or_null("ReturnDoor") as Area2D
	var wind := get_node_or_null("BossRoomWind") as AudioStreamPlayer
	if wind != null and wind.stream != null:
		wind.play()
	phase_two_packed_scene = load(phase_two_scene) as PackedScene
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
	_play_boss_music()


func _complete_boss_fight() -> void:
	if phase_two_transitioning:
		return
	boss_active = false
	boss_ref = null
	_start_phase_two_transition()


func _on_demo_boss_defeated_started(_boss: Node) -> void:
	if phase_two_transitioning:
		return
	boss_active = false
	boss_ref = null
	_start_phase_two_transition()


func _start_phase_two_transition() -> void:
	phase_two_transitioning = true
	_set_return_door_locked(false)
	_focus_arena_audio(false)
	_shake_player_camera(phase_two_transition_shake_duration, phase_two_transition_shake_strength)
	await get_tree().create_timer(phase_two_transition_delay, true, false, true).timeout
	var remaining_shake := maxf(phase_two_transition_shake_duration - phase_two_transition_delay, phase_two_entry_shake_min_duration)
	GameState.set_pending_transition_shake(remaining_shake, phase_two_transition_shake_strength)
	GameState.set_input_locked(false)
	if phase_two_packed_scene != null:
		get_tree().change_scene_to_packed(phase_two_packed_scene)
	else:
		get_tree().change_scene_to_file(phase_two_scene)


func _shake_player_camera(duration: float, strength: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", duration, strength)
	else:
		DEMO_COMBAT_JUICE.shake_camera(self, duration, strength)


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


func _play_boss_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_boss_music"):
		music_player.play_boss_music()
