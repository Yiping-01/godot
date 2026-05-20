extends Node2D
class_name DebugHitboxOverlay

@export var toggle_key := KEY_F3
@export var toggle_action := "debug_hitboxes"
@export var line_width := 2.0
@export var active_alpha := 1.0
@export var inactive_alpha := 0.55

const DEBUG_RED := Color(1.0, 0.02, 0.02, 1.0)
const POINTS_PER_ARC := 24

var enabled := false
var shape_lines: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	z_as_relative = false
	z_index = 4096
	global_position = Vector2.ZERO
	set_process(false)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	var pressed_debug_action: bool = InputMap.has_action(toggle_action) and event.is_action_pressed(toggle_action)
	var pressed_debug_key: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key
	if pressed_debug_action or pressed_debug_key:
		enabled = not enabled
		visible = enabled
		set_process(enabled)
		if enabled:
			_refresh_debug_objects()
		else:
			_clear_debug_objects()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	global_position = Vector2.ZERO
	_refresh_debug_objects()


func _refresh_debug_objects() -> void:
	if not enabled:
		return

	var current_keys := {}
	var root := get_tree().current_scene
	if root == null:
		_clear_debug_objects()
		return

	for shape_node in root.find_children("*", "CollisionShape2D", true, false):
		if not shape_node is CollisionShape2D:
			continue
		var collision_shape := shape_node as CollisionShape2D
		if not _should_show_shape(collision_shape):
			continue
		var key := str(collision_shape.get_instance_id())
		current_keys[key] = true
		_update_line_for_shape(key, collision_shape)

	for key in shape_lines.keys():
		if current_keys.has(key):
			continue
		var line := shape_lines[key] as Line2D
		if line != null and is_instance_valid(line):
			line.queue_free()
		shape_lines.erase(key)


func _update_line_for_shape(key: String, shape_node: CollisionShape2D) -> void:
	var points := _shape_points(shape_node)
	if points.size() < 2:
		return

	var line := _get_or_create_line(key)
	line.points = points
	line.closed = _shape_should_close(shape_node)
	line.width = line_width
	line.default_color = _shape_color(shape_node)
	line.visible = true


func _get_or_create_line(key: String) -> Line2D:
	if shape_lines.has(key):
		var existing := shape_lines[key] as Line2D
		if existing != null and is_instance_valid(existing):
			return existing

	var line := Line2D.new()
	line.name = "DebugCollision_%s" % key
	line.z_as_relative = false
	line.z_index = 4096
	line.antialiased = false
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_NONE
	line.end_cap_mode = Line2D.LINE_CAP_NONE
	add_child(line)
	shape_lines[key] = line
	return line


func _shape_color(shape_node: CollisionShape2D) -> Color:
	var color := DEBUG_RED
	color.a = active_alpha if _is_shape_active(shape_node) else inactive_alpha
	return color


func _shape_points(shape_node: CollisionShape2D) -> PackedVector2Array:
	if shape_node.shape is RectangleShape2D:
		var rectangle := shape_node.shape as RectangleShape2D
		var half := rectangle.size * 0.5
		return PackedVector2Array([
			shape_node.to_global(Vector2(-half.x, -half.y)),
			shape_node.to_global(Vector2(half.x, -half.y)),
			shape_node.to_global(Vector2(half.x, half.y)),
			shape_node.to_global(Vector2(-half.x, half.y)),
		])

	if shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		var points := PackedVector2Array()
		for index in range(POINTS_PER_ARC * 2):
			var angle := TAU * float(index) / float(POINTS_PER_ARC * 2)
			points.append(shape_node.to_global(Vector2(cos(angle), sin(angle)) * circle.radius))
		return points

	if shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		var radius := capsule.radius
		var straight := maxf(capsule.height - radius * 2.0, 0.0) * 0.5
		var points := PackedVector2Array()
		for index in range(POINTS_PER_ARC + 1):
			var top_angle := PI + PI * float(index) / float(POINTS_PER_ARC)
			points.append(shape_node.to_global(Vector2(cos(top_angle) * radius, -straight + sin(top_angle) * radius)))
		for index in range(POINTS_PER_ARC + 1):
			var bottom_angle := PI * float(index) / float(POINTS_PER_ARC)
			points.append(shape_node.to_global(Vector2(cos(bottom_angle) * radius, straight + sin(bottom_angle) * radius)))
		return points

	if shape_node.shape is ConvexPolygonShape2D:
		var polygon := shape_node.shape as ConvexPolygonShape2D
		var points := PackedVector2Array()
		for point in polygon.points:
			points.append(shape_node.to_global(point))
		return points

	if shape_node.shape is ConcavePolygonShape2D:
		var concave := shape_node.shape as ConcavePolygonShape2D
		var points := PackedVector2Array()
		for point in concave.segments:
			points.append(shape_node.to_global(point))
		return points

	return PackedVector2Array()


func _shape_should_close(shape_node: CollisionShape2D) -> bool:
	return not shape_node.shape is ConcavePolygonShape2D


func _is_shape_active(shape_node: CollisionShape2D) -> bool:
	if shape_node.disabled:
		return false
	var shape_owner := shape_node.get_parent()
	if shape_owner is Area2D:
		return shape_owner.monitoring or shape_owner.monitorable
	if shape_owner is CollisionObject2D:
		return shape_owner.collision_layer != 0 or shape_owner.collision_mask != 0
	return true


func _should_show_shape(shape_node: CollisionShape2D) -> bool:
	var shape_owner := shape_node.get_parent()
	if shape_owner == null:
		return false
	if _is_debug_noise(shape_owner):
		return false

	var current := shape_owner
	while current != null:
		if current.is_in_group("player") or current.is_in_group("enemy"):
			return true
		current = current.get_parent()

	if shape_owner is StaticBody2D or shape_owner is CharacterBody2D or shape_owner is RigidBody2D:
		return true
	if shape_owner is Area2D:
		var lower_name := String(shape_owner.name).to_lower()
		for keyword in ["attack", "damage", "hurt", "hit", "projectile", "hazard", "bodycontact", "quake"]:
			if lower_name.contains(keyword):
				return true
	return false


func _is_debug_noise(node: Node) -> bool:
	var current := node
	while current != null:
		var lower_name := String(current.name).to_lower()
		for keyword in ["tutorial", "maproom", "camera", "waterzone", "bossdoor", "returndoor", "triggerwhisper", "area_title"]:
			if lower_name.contains(keyword):
				return true
		current = current.get_parent()
	return false


func _clear_debug_objects() -> void:
	for key in shape_lines.keys():
		var line := shape_lines[key] as Line2D
		if line != null and is_instance_valid(line):
			line.queue_free()
	shape_lines.clear()
