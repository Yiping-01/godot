extends RigidBody2D

@export var value: int = 1
@export var max_horizontal_speed: float = 360.0
@export var min_up_speed: float = 420.0
@export var max_up_speed: float = 620.0
@export var pickup_delay: float = 0.25
@export var underwater_horizontal_speed: float = 42.0
@export var underwater_min_up_speed: float = 42.0
@export var underwater_max_up_speed: float = 68.0
@export var underwater_rise_time: float = 0.72
@export var underwater_drift_speed: float = 12.0
@export var underwater_drift_frequency: float = 1.4

@onready var pickup_area: Area2D = $PickupArea

var can_pickup := false
var is_underwater_pickup := false
var underwater_rise_left := 0.0
var underwater_drift_phase := 0.0


func _ready() -> void:
	gravity_scale = 1.25
	linear_damp = 0.35
	angular_damp = 1.5
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	await get_tree().create_timer(pickup_delay).timeout
	can_pickup = true


func _physics_process(delta: float) -> void:
	if not is_underwater_pickup:
		return
	if underwater_rise_left > 0.0:
		underwater_rise_left = maxf(underwater_rise_left - delta, 0.0)
		return
	underwater_drift_phase += delta * underwater_drift_frequency
	gravity_scale = 0.0
	linear_velocity = Vector2(sin(underwater_drift_phase) * underwater_drift_speed, 0.0)


func launch_from(spawn_position: Vector2) -> void:
	global_position = spawn_position
	if _is_underwater_position(spawn_position):
		is_underwater_pickup = true
		underwater_rise_left = underwater_rise_time
		underwater_drift_phase = randf_range(0.0, TAU)
		gravity_scale = 0.0
		linear_damp = 0.85
		angular_damp = 2.4
		linear_velocity = Vector2(
			randf_range(-underwater_horizontal_speed, underwater_horizontal_speed),
			-randf_range(underwater_min_up_speed, underwater_max_up_speed)
		)
		angular_velocity = randf_range(-2.5, 2.5)
		return
	var horizontal := randf_range(-max_horizontal_speed, max_horizontal_speed)
	var upward := -randf_range(min_up_speed, max_up_speed)
	linear_velocity = Vector2(horizontal, upward)
	angular_velocity = randf_range(-8.0, 8.0)


func _is_underwater_position(spawn_position: Vector2) -> bool:
	for zone in get_tree().get_nodes_in_group("water_zone"):
		if zone.has_method("contains_global_point") and zone.call("contains_global_point", spawn_position):
			return true
	return false


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if not can_pickup or not body.is_in_group("player"):
		return

	GameState.add_currency(value)
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path.begins_with("res://demo/") and ui.has_method("show_coin_gain"):
			ui.show_coin_gain(value)
			queue_free()
			return

		ui.show_toast("回收寶特瓶 +%d" % value)
	queue_free()
