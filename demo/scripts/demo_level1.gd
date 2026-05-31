extends Node2D

@export var area_title := "深海入口"
@export var area_subtitle := ""


func _ready() -> void:
	get_tree().paused = false
	GameState.set_input_locked(false)
	call_deferred("_show_area_title")


func _show_area_title() -> void:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title(area_title, area_subtitle)
