extends Node2D


func _ready() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	var player := get_node_or_null("Player")
	if player != null and player.has_method("set_camera_profile"):
		player.call("set_camera_profile", Vector2(20, 96), Vector2(1.18, 1.18), 8.5)
