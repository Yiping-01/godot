extends Area2D

@export var launch_velocity: float = -760.0
@export var reuse_cooldown: float = 0.18

var _recent_bodies: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	for body in _recent_bodies.keys():
		_recent_bodies[body] -= delta
		if _recent_bodies[body] <= 0.0:
			_recent_bodies.erase(body)
	for body in get_overlapping_bodies():
		_launch_body(body)


func _on_body_entered(body: Node) -> void:
	_launch_body(body)


func _launch_body(body: Node) -> void:
	if _recent_bodies.has(body):
		return
	if not body is CharacterBody2D:
		return

	body.velocity.y = launch_velocity
	if _has_property(body, "jump_count"):
		body.set("jump_count", 1)
	if body.has_method("_snap_camera_to_player"):
		body.call_deferred("_snap_camera_to_player")

	_recent_bodies[body] = reuse_cooldown


func _has_property(node: Node, property_name: String) -> bool:
	for property in node.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

