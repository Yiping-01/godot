extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")


func _ready() -> void:
	call_deferred("_play_entry_impact")


func _play_entry_impact() -> void:
	DEMO_COMBAT_JUICE.shake_camera(self, 0.32, 12.0)
