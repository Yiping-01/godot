extends Node2D

signal phase_finished

const HULOB_COMBAT_JUICE := preload("res://hulobOuO/scripts/hulob_combat_juice.gd")

@export var platform_root_path: NodePath
@export var player_path: NodePath
@export var phase_camera_path: NodePath
@export var player_camera_path: NodePath
@export var arena_center := Vector2(1160, 430)
@export var camera_offset := Vector2(520, 76)
@export var camera_zoom := Vector2(0.86, 0.86)
@export var wire_spawn_interval := 3.2

var player: Node2D
var platform_root: Node2D
var tentacle_root: Node2D
var wire_root: Node2D
var core: Node2D
var octopus_sprite: CanvasItem
var phase_camera: Node
var player_camera: Node
var alive_tentacles := 0
var phase_started := false
var wire_timer := 0.0
var next_wire_index := 0


func _ready() -> void:
	visible = false
	set_process(false)
	platform_root = get_node_or_null(platform_root_path) as Node2D
	player = get_node_or_null(player_path) as Node2D
	phase_camera = get_node_or_null(phase_camera_path)
	player_camera = get_node_or_null(player_camera_path)
	tentacle_root = get_node_or_null("Tentacles") as Node2D
	wire_root = get_node_or_null("Wires") as Node2D
	core = get_node_or_null("OctopusCore") as Node2D
	octopus_sprite = get_node_or_null("BackgroundOctopus") as CanvasItem
	_prepare_platforms(false)
	_prepare_phase_actors()


func start_phase() -> void:
	if phase_started:
		return
	phase_started = true
	visible = true
	set_process(true)
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.has_method("set_camera_profile"):
		player.call("set_camera_profile", camera_offset, camera_zoom, 2.4)
	_switch_phase_camera(true)
	_prepare_platforms(true)
	HULOB_COMBAT_JUICE.shake_camera(self, 1.1, 16.0)
	_reveal_octopus()
	await get_tree().create_timer(1.05).timeout
	_spawn_tentacles()


func _process(delta: float) -> void:
	if not phase_started or alive_tentacles <= 0:
		return
	wire_timer -= delta
	if wire_timer <= 0.0:
		wire_timer = wire_spawn_interval
		_spawn_wire()


func _prepare_platforms(active: bool) -> void:
	if platform_root == null:
		return
	platform_root.visible = active
	for body in platform_root.find_children("*", "StaticBody2D", true, false):
		body.collision_layer = 1 if active else 0
		body.collision_mask = 2 if active else 0
		for shape in body.find_children("*", "CollisionShape2D", true, false):
			shape.disabled = not active
	for area in platform_root.find_children("*", "Area2D", true, false):
		area.monitoring = active
		area.monitorable = active
		for shape in area.find_children("*", "CollisionShape2D", true, false):
			shape.disabled = not active


func _prepare_phase_actors() -> void:
	if octopus_sprite != null:
		octopus_sprite.visible = false
		octopus_sprite.modulate.a = 0.0
	if tentacle_root != null:
		for tentacle in tentacle_root.get_children():
			if tentacle.has_signal("defeated") and not tentacle.is_connected("defeated", Callable(self, "_on_tentacle_defeated")):
				tentacle.connect("defeated", Callable(self, "_on_tentacle_defeated"))
			if tentacle.has_method("sleep"):
				tentacle.call("sleep")
	if wire_root != null:
		for wire in wire_root.get_children():
			if wire.has_method("_break"):
				wire.call("_break")
	if core != null:
		core.visible = false
		if core.has_signal("defeated") and not core.is_connected("defeated", Callable(self, "_on_core_defeated")):
			core.connect("defeated", Callable(self, "_on_core_defeated"))


func _reveal_octopus() -> void:
	if octopus_sprite == null:
		return
	octopus_sprite.visible = true
	var start_y: float = octopus_sprite.position.y
	octopus_sprite.position.y = start_y + 170.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(octopus_sprite, "position:y", start_y, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(octopus_sprite, "modulate:a", 0.48, 0.85)
	tween.tween_property(octopus_sprite, "scale", octopus_sprite.scale * 1.08, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_tentacles() -> void:
	if tentacle_root == null:
		return
	alive_tentacles = tentacle_root.get_child_count()
	for tentacle in tentacle_root.get_children():
		if tentacle.has_method("wake"):
			tentacle.call("wake")
		await get_tree().create_timer(0.2).timeout


func _spawn_wire() -> void:
	if wire_root == null or wire_root.get_child_count() == 0:
		return
	for i in wire_root.get_child_count():
		var wire := wire_root.get_child((next_wire_index + i) % wire_root.get_child_count())
		if bool(wire.get("active")):
			continue
		next_wire_index = (next_wire_index + i + 1) % wire_root.get_child_count()
		if wire.has_method("wake"):
			wire.call("wake")
		return


func _on_tentacle_defeated(_tentacle: Node) -> void:
	alive_tentacles -= 1
	HULOB_COMBAT_JUICE.shake_camera(self, 0.26, 6.5)
	if alive_tentacles <= 0:
		_show_core()


func _show_core() -> void:
	if core == null:
		_on_core_defeated()
		return
	core.visible = true
	if core.has_method("wake"):
		core.call("wake")
	var tween := create_tween()
	core.scale = Vector2(0.35, 0.35)
	tween.tween_property(core, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	HULOB_COMBAT_JUICE.shake_camera(self, 0.55, 10.0)


func _on_core_defeated() -> void:
	phase_started = false
	set_process(false)
	_prepare_platforms(false)
	if player != null and player.has_method("reset_camera_profile"):
		player.call("reset_camera_profile")
	_switch_phase_camera(false)
	HULOB_COMBAT_JUICE.shake_camera(self, 0.8, 12.0)
	phase_finished.emit()


func _switch_phase_camera(active: bool) -> void:
	if phase_camera == null or player_camera == null:
		return
	phase_camera.set("priority", 30 if active else 0)
	player_camera.set("priority", 20 if not active else 1)
