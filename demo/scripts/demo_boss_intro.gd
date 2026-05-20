extends Area2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export var boss_path: NodePath
@export var intro_title := "Gloaming Warden"
@export var intro_subtitle := "Boss Chamber"

var triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("player"):
		return

	triggered = true
	var boss := get_node_or_null(boss_path)
	if boss is Node2D:
		boss.set_physics_process(true)

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_area_title"):
		ui.show_area_title(intro_title, intro_subtitle)

	if boss is Node2D:
		if boss.has_method("_start_intro_effect"):
			boss.call("_start_intro_effect")

	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_on_demo_boss_intro_started"):
		scene.call("_on_demo_boss_intro_started", boss)

	DEMO_COMBAT_JUICE.shake_camera(self, 0.55, 8.5)
	queue_free()
