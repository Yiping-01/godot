extends Control
class_name HulobMapCanvas

var compact := false
var _last_player_marker_position := Vector2(1.0e20, 1.0e20)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not GameState.map_room_changed.is_connected(_on_map_room_changed):
		GameState.map_room_changed.connect(_on_map_room_changed)


func _process(_delta: float) -> void:
	if not visible:
		return
	var player := get_tree().get_first_node_in_group("player")
	if not player is Node2D:
		return
	var player_position := (player as Node2D).global_position
	_last_player_marker_position = player_position
	queue_redraw()


func _draw() -> void:
	var scene_path := GameState.current_map_scene
	var current_scene := get_tree().current_scene
	if scene_path == "" and current_scene != null:
		scene_path = current_scene.scene_file_path

	var rooms := GameState.get_map_rooms(scene_path)
	_draw_panel_backdrop()
	if rooms.is_empty():
		_draw_empty_map()
		return

	var bounds := _room_bounds(rooms)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	var margin := 16.0 if compact else 34.0
	var available := size - Vector2.ONE * margin * 2.0
	var map_scale := minf(available.x / bounds.size.x, available.y / bounds.size.y)
	map_scale = clampf(map_scale, 0.18, 6.0)
	var offset := (size - bounds.size * map_scale) * 0.5 - bounds.position * map_scale

	_draw_room_connections(rooms, scene_path, offset, map_scale)
	for room_id in rooms.keys():
		var data: Dictionary = rooms[room_id]
		var rect: Rect2 = data.get("rect", Rect2())
		var screen_rect := Rect2(rect.position * map_scale + offset, rect.size * map_scale)
		var visited := GameState.is_room_visited(scene_path, String(room_id))
		var current := String(room_id) == _get_player_room_id(rooms)
		_draw_room_cell(screen_rect, visited, current)
	_draw_player_marker(rooms, scene_path, offset, map_scale)


func _draw_panel_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.035, 0.52), true)
	for x in range(0, int(size.x), 34):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x) - 40.0, size.y), Color(0.38, 0.66, 0.74, 0.035), 1.0)


func _draw_empty_map() -> void:
	var center := size * 0.5
	for index in range(4):
		var rect := Rect2(center + Vector2(float(index - 2) * 34.0, float(index % 2) * 22.0) - Vector2(18.0, 12.0), Vector2(36.0, 24.0))
		draw_rect(rect, Color(0.16, 0.28, 0.34, 0.32), true)
		draw_rect(rect, Color(0.62, 0.84, 0.86, 0.25), false, 1.5)


func _room_bounds(rooms: Dictionary) -> Rect2:
	var first := true
	var bounds := Rect2()
	for room_id in rooms.keys():
		var data: Dictionary = rooms[room_id]
		var rect: Rect2 = data.get("rect", Rect2())
		if first:
			bounds = rect
			first = false
		else:
			bounds = bounds.merge(rect)
	return bounds.grow(22.0)


func _draw_room_connections(rooms: Dictionary, scene_path: String, offset: Vector2, map_scale: float) -> void:
	var ids := rooms.keys()
	for a_index in range(ids.size()):
		for b_index in range(a_index + 1, ids.size()):
			var a_id := String(ids[a_index])
			var b_id := String(ids[b_index])
			var a_data: Dictionary = rooms[a_id]
			var b_data: Dictionary = rooms[b_id]
			var a_rect: Rect2 = a_data.get("rect", Rect2())
			var b_rect: Rect2 = b_data.get("rect", Rect2())
			var a_center := a_rect.get_center()
			var b_center := b_rect.get_center()
			var delta := (b_center - a_center).abs()
			var connected := (delta.x <= 180.0 and delta.y <= 98.0) or (delta.x <= 110.0 and delta.y <= 150.0)
			if not connected:
				continue

			var visible := GameState.is_room_visited(scene_path, a_id) or GameState.is_room_visited(scene_path, b_id)
			var line_color := Color(0.32, 0.62, 0.68, 0.22 if visible else 0.08)
			draw_line(a_center * map_scale + offset, b_center * map_scale + offset, line_color, 3.0 if not compact else 2.0)


func _draw_room_cell(rect: Rect2, visited: bool, current: bool) -> void:
	var fill := Color(0.08, 0.15, 0.18, 0.42)
	var border := Color(0.4, 0.66, 0.7, 0.26)
	if visited:
		fill = Color(0.16, 0.32, 0.38, 0.72)
		border = Color(0.62, 0.84, 0.86, 0.64)
	if current:
		fill = Color(0.9, 0.94, 0.84, 0.92)
		border = Color(1.0, 1.0, 1.0, 0.95)

	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0 if compact else 3.0)


func _draw_player_marker(rooms: Dictionary, _active_scene_path: String, offset: Vector2, map_scale: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player is Node2D:
		return
	var room_id := _get_player_room_id(rooms)
	if room_id == "":
		return
	var data: Dictionary = rooms[room_id]
	var room_rect: Rect2 = data.get("rect", Rect2())
	var world_rect: Rect2 = data.get("world_rect", Rect2())
	if room_rect.size == Vector2.ZERO or world_rect.size == Vector2.ZERO:
		return
	var player_position := (player as Node2D).global_position
	var x_ratio := clampf(inverse_lerp(world_rect.position.x, world_rect.end.x, player_position.x), 0.0, 1.0)
	var y_ratio := clampf(inverse_lerp(world_rect.position.y, world_rect.end.y, player_position.y), 0.0, 1.0)
	var map_position := room_rect.position + Vector2(room_rect.size.x * x_ratio, room_rect.size.y * y_ratio)
	var screen_position := map_position * map_scale + offset
	var radius := 5.0 if compact else 8.0
	draw_circle(screen_position, radius * 2.1, Color(0.62, 0.95, 1.0, 0.20))
	draw_circle(screen_position, radius * 1.25, Color(0.76, 0.98, 1.0, 0.70))
	draw_circle(screen_position, radius * 0.55, Color(0.96, 1.0, 0.98, 1.0))
	draw_arc(screen_position, radius + 3.0, 0.0, TAU, 32, Color(0.92, 1.0, 0.96, 0.95), 2.4)


func _get_player_room_id(rooms: Dictionary) -> String:
	var player := get_tree().get_first_node_in_group("player")
	if not player is Node2D:
		return ""

	var player_position := (player as Node2D).global_position
	var nearest_room_id := ""
	var nearest_distance := INF
	for room_id in rooms.keys():
		var data: Dictionary = rooms[room_id]
		var world_rect: Rect2 = data.get("world_rect", Rect2())
		if world_rect.size != Vector2.ZERO and world_rect.grow(8.0).has_point(player_position):
			return String(room_id)
		if world_rect.size != Vector2.ZERO:
			var clamped := Vector2(
				clampf(player_position.x, world_rect.position.x, world_rect.end.x),
				clampf(player_position.y, world_rect.position.y, world_rect.end.y)
			)
			var distance := player_position.distance_squared_to(clamped)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_room_id = String(room_id)

	if nearest_room_id != "":
		return nearest_room_id
	if rooms.has(GameState.current_map_room):
		return GameState.current_map_room
	return ""


func _on_map_room_changed(_scene_path: String, _room_id: String) -> void:
	queue_redraw()
