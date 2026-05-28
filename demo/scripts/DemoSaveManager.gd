extends Node

const SAVE_PATH := "user://demo_save_data.json"
const RANKING_PATH := "user://demo_ranking_data.json"

var current_player_name := ""
var current_play_time := 0.0
var timer_running := false


func _process(delta: float) -> void:
	if timer_running:
		current_play_time += delta


func start_new_game(player_name: String, start_scene: String, start_position: Vector2) -> void:
	current_player_name = player_name.strip_edges()
	current_play_time = 0.0
	timer_running = false
	save_game(start_scene, start_position)


func save_game(scene_path: String, player_position: Vector2) -> void:
	if current_player_name.is_empty():
		return

	var save_data := _read_json_dictionary(SAVE_PATH)
	save_data[current_player_name] = {
		"player_name": current_player_name,
		"current_scene": scene_path,
		"position_x": player_position.x,
		"position_y": player_position.y,
		"play_time": current_play_time,
		"completed": false,
	}
	_write_json(SAVE_PATH, save_data)


func load_game(player_name: String) -> Dictionary:
	var cleaned_name := player_name.strip_edges()
	if cleaned_name.is_empty():
		return {}

	var save_data := _read_json_dictionary(SAVE_PATH)
	var player_save: Variant = save_data.get(cleaned_name, {})
	if player_save is Dictionary:
		current_player_name = cleaned_name
		current_play_time = float(player_save.get("play_time", 0.0))
		return player_save as Dictionary
	return {}


func has_save(player_name: String) -> bool:
	var cleaned_name := player_name.strip_edges()
	if cleaned_name.is_empty():
		return false

	var save_data := _read_json_dictionary(SAVE_PATH)
	return save_data.has(cleaned_name)


func start_timer() -> void:
	timer_running = true


func stop_timer() -> void:
	timer_running = false


func reset_timer() -> void:
	current_play_time = 0.0


func get_play_time() -> float:
	return current_play_time


func finish_game() -> void:
	if current_player_name.is_empty():
		return

	stop_timer()
	add_ranking(current_player_name, current_play_time)

	var save_data := _read_json_dictionary(SAVE_PATH)
	if save_data.has(current_player_name) and save_data[current_player_name] is Dictionary:
		save_data[current_player_name]["completed"] = true
		save_data[current_player_name]["play_time"] = current_play_time
		_write_json(SAVE_PATH, save_data)


func add_ranking(player_name: String, play_time: float) -> void:
	var cleaned_name := player_name.strip_edges()
	if cleaned_name.is_empty():
		return

	var rankings := get_rankings()
	rankings.append({
		"player_name": cleaned_name,
		"play_time": play_time,
	})
	rankings.sort_custom(Callable(self, "_sort_ranking_by_play_time"))
	_write_json(RANKING_PATH, rankings)


func get_rankings() -> Array:
	var ranking_data: Variant = _read_json(RANKING_PATH, [])
	if not (ranking_data is Array):
		return []

	var rankings: Array = (ranking_data as Array).duplicate()
	rankings.sort_custom(Callable(self, "_sort_ranking_by_play_time"))
	return rankings


func _sort_ranking_by_play_time(a: Variant, b: Variant) -> bool:
	var a_time := INF
	var b_time := INF
	if a is Dictionary:
		a_time = float(a.get("play_time", INF))
	if b is Dictionary:
		b_time = float(b.get("play_time", INF))
	return a_time < b_time


func _read_json_dictionary(path: String) -> Dictionary:
	var data: Variant = _read_json(path, {})
	if data is Dictionary:
		return data as Dictionary
	return {}


func _read_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback

	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		return fallback
	return parsed


func _write_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write demo save data to %s" % path)
		return

	file.store_string(JSON.stringify(data, "\t"))
