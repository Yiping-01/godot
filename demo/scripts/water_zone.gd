extends Area2D
class_name WaterZone

@export var camera_limit_left: int = -10000000
@export var camera_limit_top: int = -10000000
@export var camera_limit_right: int = 10000000
@export var camera_limit_bottom: int = 10000000
@export var apply_camera_limits := true
@export var bounds_source_path: NodePath


func _ready() -> void:
	add_to_group("water_zone")
	_sync_bounds_to_source()
	call_deferred("_connect_body_signals")


func _connect_body_signals() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	_apply_to_overlapping_players()


func _sync_bounds_to_source() -> void:
	if bounds_source_path.is_empty():
		return

	var source := get_node_or_null(bounds_source_path)
	if not source is Polygon2D:
		return

	var rect := _get_polygon_world_rect(source as Polygon2D)
	if rect.size == Vector2.ZERO:
		return

	global_position = rect.get_center()
	var shape_node := get_node_or_null("CollisionShape2D")
	if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		rect_shape.size = rect.size / global_scale.abs()


func _get_polygon_world_rect(polygon_node: Polygon2D) -> Rect2:
	if polygon_node.polygon.is_empty():
		return Rect2()

	var first := polygon_node.to_global(polygon_node.polygon[0])
	var rect := Rect2(first, Vector2.ZERO)
	for point in polygon_node.polygon:
		rect = rect.expand(polygon_node.to_global(point))
	return rect


func _apply_to_overlapping_players() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("set_water_surface_y"):
		body.set_water_surface_y(_get_surface_y())
	if body.has_method("set_underwater"):
		body.set_underwater(true)
	if apply_camera_limits and body.has_method("set_camera_limits"):
		body.set_camera_limits(camera_limit_left, camera_limit_top, camera_limit_right, camera_limit_bottom)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if bool(body.get("is_dead")):
		return

	if body.has_method("set_underwater"):
		body.set_underwater(false)
	if body.has_method("clear_water_surface_y"):
		body.clear_water_surface_y()
	if apply_camera_limits:
		if body.has_method("reset_camera_after_water_exit"):
			body.reset_camera_after_water_exit()
			return
		if body.has_method("reset_camera_limits"):
			body.reset_camera_limits()
		if body.has_method("reset_camera_profile"):
			body.reset_camera_profile()


func _get_surface_y() -> float:
	var shape_node := get_node_or_null("CollisionShape2D")
	if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		var shape_height := rect_shape.size.y * absf(shape_node.global_scale.y)
		return shape_node.global_position.y - shape_height * 0.5
	return global_position.y


func contains_global_point(point: Vector2) -> bool:
	var shape_node := get_node_or_null("CollisionShape2D")
	if not shape_node is CollisionShape2D or not shape_node.shape is RectangleShape2D:
		return false
	var rect_shape: RectangleShape2D = shape_node.shape
	var local_point: Vector2 = shape_node.to_local(point)
	return Rect2(-rect_shape.size * 0.5, rect_shape.size).has_point(local_point)


func reapply_to_player_if_overlapping(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if get_overlapping_bodies().has(body):
		_on_body_entered(body)
