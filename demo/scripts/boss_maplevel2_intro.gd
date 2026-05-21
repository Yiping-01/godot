extends Node2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")

@export var entry_shake_duration := 0.58
@export var entry_shake_strength := 13.5


func _ready() -> void:
	_play_entry_impact()


func _play_entry_impact() -> void:
	var shake := GameState.consume_pending_transition_shake()
	var duration := float(shake.get("duration", 0.0))
	var strength := float(shake.get("strength", 0.0))
	if duration <= 0.0 or strength <= 0.0:
		duration = entry_shake_duration
		strength = entry_shake_strength
	DEMO_COMBAT_JUICE.shake_camera(self, duration, strength)
