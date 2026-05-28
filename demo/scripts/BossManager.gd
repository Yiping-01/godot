extends Node2D

signal boss_health_changed(current: int, maximum: int)
signal boss_defeated

const BOSS_NORMAL_BACKGROUND := preload("res://demo/assets/background/bosslevel_bgtitle/bosslevel2bg.png")
const BOSS_CORE_OPEN_BACKGROUND := preload("res://demo/assets/background/bosslevel_bgtitle/bosslevel2_habg.png")
const BOSS_END_BACKGROUND := preload("res://demo/assets/background/bosslevel_bgtitle/boss_end_bg.png")

@export var max_health := 100
@export var monster_id := "Boss"
@export var phase_two_threshold := 60
@export var core_open_duration := 6.0
@export var tentacle_respawn_delay := 1.2
@export var wire_round_count := 3
@export var wire_round_time := 50.0
@export var wire_round_cooldown := 3.0
@export var wire_warning_start_time := 5.0
@export var wire_fast_warning_start_time := 3.0
@export var lightning_strike_count := 3
@export var lightning_strike_interval := 0.8
@export var lightning_random_min_x := 118.0
@export var lightning_random_max_x := 1712.0
@export var lightning_near_player_radius := 420.0
@export var lightning_min_spacing := 220.0
@export var enraged_wire_round_time := 35.0
@export var enraged_lightning_strike_interval := 0.5
@export var enraged_core_open_duration := 3.5
@export var debug_start_phase_two := false
@export var phase_two_hint_duration := 0.65
@export var phase_two_hint_hold_time := 0.22
@export var phase_two_hint_shake_duration := 0.35
@export var phase_two_hint_shake_strength := 10.0
@export var low_health_hint_threshold := 30
@export var low_health_hint_duration := 0.22
@export var low_health_hint_hold_time := 0.12
@export var low_health_hint_shake_duration := 0.28
@export var low_health_hint_shake_strength := 8.0
@export var enraged_hint_duration := 3.0
@export var enraged_hint_flash_interval := 0.16
@export var enraged_hint_shake_strength := 18.0
@export var electric_wire_scene: PackedScene
@export var lightning_area_scene: PackedScene
@export var tentacles_path: NodePath
@export var boss_core_path: NodePath
@export var boss_body_path: NodePath
@export var core_open_background_path: NodePath
@export var wire_spawn_points_path: NodePath
@export var lightning_spawn_points_path: NodePath

var health := 0
var phase := 1
var boss_dead := false
var core_open := false
var enraged := false
var active_wires: Array[Node] = []
var wire_round_running := false
var phase_two_started := false
var low_health_hint_started := false
var active_attacking_tentacle: Node
var phase_two_hint_canvas_modulate: CanvasModulate
var phase_two_hint_tween: Tween

@onready var tentacles_root: Node = get_node_or_null(tentacles_path)
@onready var boss_core: Node = get_node_or_null(boss_core_path)
@onready var boss_body: CanvasItem = get_node_or_null(boss_body_path) as CanvasItem
@onready var core_open_background: CanvasItem = get_node_or_null(core_open_background_path) as CanvasItem
@onready var wire_spawn_points: Node = get_node_or_null(wire_spawn_points_path)
@onready var lightning_spawn_points: Node = get_node_or_null(lightning_spawn_points_path)


func _get_current_wire_round_time() -> float:
	var value := enraged_wire_round_time if enraged else wire_round_time
	print("wire round time:", value, " enraged:", enraged)
	return value


func _get_current_lightning_interval() -> float:
	var value := enraged_lightning_strike_interval if enraged else lightning_strike_interval
	print("lightning interval:", value, " enraged:", enraged)
	return value


func _get_current_core_open_duration() -> float:
	var value := enraged_core_open_duration if enraged else core_open_duration
	print("core open duration:", value, " enraged:", enraged)
	return value


func _ready() -> void:
	health = max_health
	_setup_phase_two_hint_canvas_modulate()
	_connect_tentacles()
	if boss_core != null and boss_core.has_method("set_manager"):
		boss_core.call("set_manager", self)
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	_respawn_tentacles()
	boss_health_changed.emit(health, max_health)
	if debug_start_phase_two:
		call_deferred("_enter_phase_two")


func on_tentacle_died(_tentacle: Node) -> void:
	if active_attacking_tentacle == _tentacle:
		active_attacking_tentacle = null
	if boss_dead or core_open:
		return
	if _all_tentacles_dead():
		await get_tree().create_timer(tentacle_respawn_delay).timeout
		if not boss_dead:
			_open_core()


func can_tentacle_attack(tentacle: Node) -> bool:
	if boss_dead or core_open:
		return false
	if active_attacking_tentacle != null and not is_instance_valid(active_attacking_tentacle):
		active_attacking_tentacle = null
	if active_attacking_tentacle == null or active_attacking_tentacle == tentacle:
		active_attacking_tentacle = tentacle
		return true
	return false


func on_tentacle_attack_finished(tentacle: Node) -> void:
	if active_attacking_tentacle == tentacle:
		active_attacking_tentacle = null


func damage_boss(amount: int) -> void:
	if boss_dead or not core_open:
		return

	health = maxi(health - amount, 0)
	print("Boss HP: %d / %d" % [health, max_health])
	boss_health_changed.emit(health, max_health)
	if health <= 0:
		_die()
		return

	if not low_health_hint_started and health <= low_health_hint_threshold:
		_play_low_health_hint()

	if not enraged and health <= low_health_hint_threshold:
		enraged = true
		print("Boss enraged:", enraged)
		_play_enraged_mode_hint()

	if phase == 1 and health <= phase_two_threshold:
		_enter_phase_two()


func trigger_lightning(strike_position: Variant = null) -> void:
	if boss_dead or lightning_area_scene == null:
		return

	var lightning: Node = lightning_area_scene.instantiate()
	add_child(lightning)
	if lightning is Node2D:
		var target_position := _pick_spawn_position(lightning_spawn_points)
		if strike_position is Vector2:
			target_position = strike_position
		(lightning as Node2D).global_position = target_position


func _open_core() -> void:
	core_open = true
	active_attacking_tentacle = null
	_set_tentacles_active(false)
	_set_boss_body_core_open(true)
	if boss_core != null:
		if boss_core.has_method("show_core"):
			boss_core.call("show_core")
		elif boss_core.has_method("open_core"):
			boss_core.call("open_core")

	await get_tree().create_timer(_get_current_core_open_duration()).timeout
	if not boss_dead:
		_close_core_and_respawn()


func _close_core_and_respawn() -> void:
	core_open = false
	_set_boss_body_core_open(false)
	if boss_core != null:
		if boss_core.has_method("hide_core"):
			boss_core.call("hide_core")
		elif boss_core.has_method("close_core"):
			boss_core.call("close_core")
	_respawn_tentacles()


func _respawn_tentacles() -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_manager"):
			child.call("set_manager", self)
		if child.has_method("respawn"):
			child.call("respawn")


func _set_tentacles_active(active: bool) -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_active"):
			child.call("set_active", active)


func _set_boss_body_core_open(is_core_open: bool) -> void:
	if core_open_background != null:
		if core_open_background is Sprite2D:
			var background := core_open_background as Sprite2D
			background.texture = BOSS_CORE_OPEN_BACKGROUND if is_core_open else BOSS_NORMAL_BACKGROUND
		if is_core_open:
			core_open_background.modulate = Color(0.52, 0.52, 0.58, 1.0)
		else:
			core_open_background.modulate = Color.WHITE
	if boss_body != null:
		if is_core_open:
			boss_body.modulate = Color(0.45, 0.45, 0.45, 0.65)
		else:
			boss_body.modulate = Color(1.0, 1.0, 1.0, 0.75)
	if boss_body is AnimatedSprite2D:
		var boss_sprite := boss_body as AnimatedSprite2D
		if is_core_open:
			boss_sprite.play("core_open")
		else:
			boss_sprite.play("idle")


func _connect_tentacles() -> void:
	if tentacles_root == null:
		return
	for child in tentacles_root.get_children():
		if child.has_method("set_manager"):
			child.call("set_manager", self)


func _all_tentacles_dead() -> bool:
	if tentacles_root == null:
		return true
	for child in tentacles_root.get_children():
		if child.has_method("is_dead") and not bool(child.call("is_dead")):
			return false
	return true


func _enter_phase_two() -> void:
	if phase_two_started:
		return
	phase = 2
	phase_two_started = true
	print("Boss phase 2 started")
	_play_phase_two_transition_hint()
	call_deferred("_start_wire_round_loop")


func _setup_phase_two_hint_canvas_modulate() -> void:
	phase_two_hint_canvas_modulate = CanvasModulate.new()
	phase_two_hint_canvas_modulate.name = "PhaseTwoHintCanvasModulate"
	phase_two_hint_canvas_modulate.color = Color.WHITE
	add_child(phase_two_hint_canvas_modulate)


func _play_phase_two_transition_hint() -> void:
	if phase_two_hint_canvas_modulate == null:
		return
	if phase_two_hint_tween != null:
		phase_two_hint_tween.kill()

	var deep_blue := Color(0.043, 0.063, 0.125, 1.0) # #0B1020
	var dark_red := Color(0.133, 0.024, 0.039, 1.0) # #22060A
	phase_two_hint_canvas_modulate.color = deep_blue
	_flash_boss_core_for_phase_two()
	_shake_phase_two_camera()

	phase_two_hint_tween = create_tween()
	phase_two_hint_tween.tween_property(
		phase_two_hint_canvas_modulate,
		"color",
		dark_red,
		phase_two_hint_duration
	)
	phase_two_hint_tween.tween_interval(phase_two_hint_hold_time)
	phase_two_hint_tween.tween_property(
		phase_two_hint_canvas_modulate,
		"color",
		Color.WHITE,
		0.35
	)


func _play_low_health_hint() -> void:
	if phase_two_hint_canvas_modulate == null:
		return
	low_health_hint_started = true
	if phase_two_hint_tween != null:
		phase_two_hint_tween.kill()

	var warning_red := Color(1.0, 0.68, 0.66, 1.0)
	_flash_boss_core_for_phase_two()
	_shake_phase_two_camera(low_health_hint_shake_duration, low_health_hint_shake_strength)

	phase_two_hint_canvas_modulate.color = Color.WHITE
	phase_two_hint_tween = create_tween()
	phase_two_hint_tween.tween_property(
		phase_two_hint_canvas_modulate,
		"color",
		warning_red,
		low_health_hint_duration
	)
	phase_two_hint_tween.tween_interval(low_health_hint_hold_time)
	phase_two_hint_tween.tween_property(
		phase_two_hint_canvas_modulate,
		"color",
		Color.WHITE,
		0.35
	)


func _play_enraged_mode_hint() -> void:
	if phase_two_hint_canvas_modulate == null:
		return
	if phase_two_hint_tween != null:
		phase_two_hint_tween.kill()

	_flash_boss_core_for_phase_two()
	_shake_phase_two_camera(enraged_hint_duration, enraged_hint_shake_strength)

	var dark_flash := Color(0.02, 0.0, 0.0, 1.0)
	var bright_flash := Color(1.35, 1.18, 1.08, 1.0)
	phase_two_hint_canvas_modulate.color = dark_flash
	phase_two_hint_tween = create_tween()
	var elapsed := 0.0
	var use_bright := true
	while elapsed < enraged_hint_duration:
		phase_two_hint_tween.tween_property(
			phase_two_hint_canvas_modulate,
			"color",
			bright_flash if use_bright else dark_flash,
			enraged_hint_flash_interval
		)
		elapsed += enraged_hint_flash_interval
		use_bright = not use_bright
	phase_two_hint_tween.tween_property(
		phase_two_hint_canvas_modulate,
		"color",
		Color.WHITE,
		0.25
	)


func _flash_boss_core_for_phase_two() -> void:
	if boss_core == null:
		return
	if boss_core.has_method("flash_hit"):
		boss_core.call("flash_hit")


func _shake_phase_two_camera(duration: float = -1.0, strength: float = -1.0) -> void:
	var shake_duration := phase_two_hint_shake_duration if duration < 0.0 else duration
	var shake_strength := phase_two_hint_shake_strength if strength < 0.0 else strength
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		camera = get_node_or_null("../Camera2D") as Camera2D
	if camera != null:
		if camera.has_method("shake"):
			camera.call("shake", shake_duration, shake_strength)
			return
		if camera.has_method("start_shake"):
			camera.call("start_shake", shake_duration, shake_strength)
			return

	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", shake_duration, shake_strength)
		return

	pass # TODO: Add a Camera2D shake method for BossManager screen-shake hints.


func _start_wire_round_loop() -> void:
	while is_inside_tree() and phase_two_started and not boss_dead:
		await _run_wire_round()
		if boss_dead:
			return
		await get_tree().create_timer(wire_round_cooldown).timeout


func _run_wire_round() -> void:
	if boss_dead or electric_wire_scene == null:
		return

	wire_round_running = true
	active_wires.clear()
	_spawn_wire_round()

	var elapsed := 0.0
	var current_wire_round_time := _get_current_wire_round_time()
	while elapsed < current_wire_round_time and not boss_dead:
		_clean_active_wires()
		if active_wires.is_empty():
			print("Wire round cleared")
			wire_round_running = false
			return
		var remaining_time := current_wire_round_time - elapsed
		_update_wire_countdown_warning(remaining_time)
		var wait_time := minf(0.1, current_wire_round_time - elapsed)
		await get_tree().create_timer(wait_time).timeout
		elapsed += wait_time

	if boss_dead:
		return

	_clean_active_wires()
	if not active_wires.is_empty():
		for wire in active_wires:
			if is_instance_valid(wire):
				if wire.has_method("clear_countdown_warning"):
					wire.call("clear_countdown_warning")
				wire.queue_free()
		active_wires.clear()
		await _start_lightning_sequence()

	wire_round_running = false


func _spawn_wire_round() -> void:
	if electric_wire_scene == null:
		return
	var points := _get_spawn_points(wire_spawn_points)
	points.shuffle()
	var count: int = mini(wire_round_count, points.size())

	for i in range(count):
		var spawn_point := points[i]
		var wire: Node = electric_wire_scene.instantiate()
		if wire.has_method("set_manager"):
			wire.call("set_manager", self)
		add_child(wire)
		active_wires.append(wire)
		if wire is Node2D:
			(wire as Node2D).global_position = spawn_point.global_position
			(wire as Node2D).global_rotation = spawn_point.global_rotation
		if wire.has_method("set_wire_length_scale") and spawn_point.has_meta("wire_length_scale"):
			wire.call("set_wire_length_scale", float(spawn_point.get_meta("wire_length_scale")))
		if wire.has_method("set_weak_point_y_range") and spawn_point.has_meta("weak_point_min_y") and spawn_point.has_meta("weak_point_max_y"):
			wire.call(
				"set_weak_point_y_range",
				float(spawn_point.get_meta("weak_point_min_y")),
				float(spawn_point.get_meta("weak_point_max_y"))
			)
		if wire.has_method("set_weak_point_x_range") and spawn_point.has_meta("weak_point_min_x") and spawn_point.has_meta("weak_point_max_x"):
			wire.call(
				"set_weak_point_x_range",
				float(spawn_point.get_meta("weak_point_min_x")),
				float(spawn_point.get_meta("weak_point_max_x"))
			)


func _update_wire_countdown_warning(remaining_time: float) -> void:
	var warning_level := 0
	if remaining_time <= wire_fast_warning_start_time:
		warning_level = 2
	elif remaining_time <= wire_warning_start_time:
		warning_level = 1

	for wire in active_wires:
		if is_instance_valid(wire) and wire.has_method("set_countdown_warning_level"):
			wire.call("set_countdown_warning_level", warning_level)


func on_wire_destroyed(wire: Node) -> void:
	active_wires.erase(wire)
	if wire_round_running and active_wires.is_empty():
		print("Wire round cleared")
		wire_round_running = false


func _start_lightning_sequence() -> void:
	if boss_dead:
		return
	var wave_count := 2 if enraged else 1
	for wave_index in range(wave_count):
		if boss_dead:
			return
		for strike_position in _pick_near_player_lightning_positions(lightning_strike_count):
			trigger_lightning(strike_position)
		if wave_index < wave_count - 1:
			await get_tree().create_timer(_get_current_lightning_interval()).timeout


func _clean_active_wires() -> void:
	var remaining_wires: Array[Node] = []
	for wire in active_wires:
		if is_instance_valid(wire):
			remaining_wires.append(wire)
	active_wires = remaining_wires


func _get_spawn_points(points_root: Node) -> Array[Node2D]:
	var points: Array[Node2D] = []
	if points_root == null:
		return points
	for child in points_root.get_children():
		if child is Node2D:
			points.append(child as Node2D)
	return points


func _pick_spawn_position(points_root: Node) -> Vector2:
	if points_root == null or points_root.get_child_count() == 0:
		return global_position
	var candidates: Array = points_root.get_children()
	var point: Node = candidates.pick_random()
	if point is Node2D:
		return (point as Node2D).global_position
	return global_position


func _pick_random_lightning_position() -> Vector2:
	var base_position := _pick_spawn_position(lightning_spawn_points)
	base_position.x = randf_range(lightning_random_min_x, lightning_random_max_x)
	return base_position


func _pick_near_player_lightning_positions(count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var base_position := _pick_spawn_position(lightning_spawn_points)
	var center_x := _get_player_x()
	var min_x := maxf(lightning_random_min_x, center_x - lightning_near_player_radius)
	var max_x := minf(lightning_random_max_x, center_x + lightning_near_player_radius)
	if min_x > max_x:
		min_x = lightning_random_min_x
		max_x = lightning_random_max_x

	var picked_x_values: Array[float] = []
	var attempts := maxi(24, count * 16)
	while picked_x_values.size() < count and attempts > 0:
		attempts -= 1
		var candidate_x := randf_range(min_x, max_x)
		if _is_lightning_x_far_enough(candidate_x, picked_x_values):
			picked_x_values.append(candidate_x)

	if picked_x_values.size() < count:
		picked_x_values = _build_even_lightning_x_values(center_x, count)

	for x in picked_x_values:
		positions.append(Vector2(x, base_position.y))
	return positions


func _is_lightning_x_far_enough(candidate_x: float, picked_x_values: Array[float]) -> bool:
	for x in picked_x_values:
		if absf(candidate_x - x) < lightning_min_spacing:
			return false
	return true


func _build_even_lightning_x_values(center_x: float, count: int) -> Array[float]:
	var values: Array[float] = []
	if count <= 0:
		return values
	var start_x := center_x - lightning_min_spacing * float(count - 1) * 0.5
	for i in range(count):
		values.append(clampf(start_x + lightning_min_spacing * float(i), lightning_random_min_x, lightning_random_max_x))
	values.shuffle()
	return values


func _get_player_x() -> float:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return (player as Node2D).global_position.x
	var fallback_player := get_node_or_null("../Player")
	if fallback_player is Node2D:
		return (fallback_player as Node2D).global_position.x
	return _pick_spawn_position(lightning_spawn_points).x


func _pick_spawn_point(points_root: Node) -> Node2D:
	if points_root == null or points_root.get_child_count() == 0:
		return null
	var candidates: Array = points_root.get_children()
	var picked_node: Node = candidates.pick_random()
	if picked_node is Node2D:
		return picked_node as Node2D
	return null


func _die() -> void:
	boss_dead = true
	_unlock_kill_achievement()
	phase_two_started = false
	wire_round_running = false
	core_open = false
	active_attacking_tentacle = null
	for wire in active_wires:
		if is_instance_valid(wire):
			wire.queue_free()
	active_wires.clear()
	_set_tentacles_active(false)
	if boss_core != null and boss_core.has_method("close_core"):
		boss_core.call("close_core")
	if boss_body != null:
		boss_body.visible = false
	_set_end_background()
	boss_defeated.emit()


func _unlock_kill_achievement() -> void:
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_method("unlock_kill_achievement"):
		achievement_manager.call("unlock_kill_achievement", monster_id)


func _set_end_background() -> void:
	if core_open_background is Sprite2D:
		var background := core_open_background as Sprite2D
		background.texture = BOSS_END_BACKGROUND
		background.modulate = Color.WHITE
		background.visible = true

