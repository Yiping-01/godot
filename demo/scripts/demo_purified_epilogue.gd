extends Node2D

const CURRENT_SCENE := "res://demo/scenes/levels/demo_purified_epilogue.tscn"


func _ready() -> void:
	GameState.set_input_locked(false)
	GameState.save_continue_scene(CURRENT_SCENE, Vector2.ZERO, false, "purified_entry")
	GameState.save_game()
	var player := get_node_or_null("Player")
	if player != null and player.has_method("set_camera_limits"):
		player.call_deferred("set_camera_limits", 0, 0, 1920, 1080)
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_game_music"):
		music_player.play_game_music()
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title("淨化後的海溝", "濁流散去，回程的門已經開啟")
