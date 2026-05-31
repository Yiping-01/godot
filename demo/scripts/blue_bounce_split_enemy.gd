extends "res://demo/scripts/legacy_split_enemy.gd"

@export var bounce_velocity := Vector2(170.0, -130.0)
@export var bounce_min := Vector2(-650.0, 90.0)
@export var bounce_max := Vector2(300.0, 360.0)
@export var blue_modulate := Color(0.35, 0.72, 1.0, 1.0)
@export var pulse_idle_time := 0.85
@export var pulse_windup_time := 0.3
@export var pulse_active_time := 0.28
@export var pulse_recovery_time := 0.5

var pulse_state := &"pulse_idle"
var pulse_timer := 0.0


func _ready() -> void:
	super._ready()
	respawn_scene_path = "res://demo/scenes/blue_bounce_split_enemy.tscn"
	anim.modulate = blue_modulate
	pulse_state = &"pulse_idle"
	pulse_timer = pulse_idle_time


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_damage_pulse(delta)
	velocity = bounce_velocity
	move_and_slide()

	if is_on_wall():
		bounce_velocity.x *= -1.0
	if is_on_floor() or is_on_ceiling():
		bounce_velocity.y *= -1.0

	if global_position.x <= bounce_min.x:
		global_position.x = bounce_min.x
		bounce_velocity.x = absf(bounce_velocity.x)
	elif global_position.x >= bounce_max.x:
		global_position.x = bounce_max.x
		bounce_velocity.x = -absf(bounce_velocity.x)

	if global_position.y <= bounce_min.y:
		global_position.y = bounce_min.y
		bounce_velocity.y = absf(bounce_velocity.y)
	elif global_position.y >= bounce_max.y:
		global_position.y = bounce_max.y
		bounce_velocity.y = -absf(bounce_velocity.y)

	direction = 1 if bounce_velocity.x > 0.0 else -1
	anim.flip_h = direction > 0
	_damage_current_attack_overlaps()


func _update_damage_pulse(delta: float) -> void:
	pulse_timer -= delta
	match pulse_state:
		&"pulse_windup":
			var progress := 1.0 - pulse_timer / maxf(pulse_windup_time, 0.001)
			anim.modulate = blue_modulate.lerp(Color(1.0, 0.9, 0.45, 1.0), progress)
			if pulse_timer <= 0.0:
				pulse_state = &"attack"
				pulse_timer = pulse_active_time
				anim.modulate = Color(1.0, 0.9, 0.45, 1.0)
				call_deferred("_damage_current_attack_overlaps")
		&"attack":
			if pulse_timer <= 0.0:
				pulse_state = &"pulse_recovery"
				pulse_timer = pulse_recovery_time
				anim.modulate = blue_modulate
		&"pulse_recovery":
			if pulse_timer <= 0.0:
				pulse_state = &"pulse_idle"
				pulse_timer = pulse_idle_time
		_:
			anim.modulate = blue_modulate
			if pulse_timer <= 0.0:
				pulse_state = &"pulse_windup"
				pulse_timer = pulse_windup_time


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	anim.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(anim, "modulate", blue_modulate, hurt_flash_time)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	_damage_attack_body(body)


func _damage_current_attack_overlaps() -> void:
	if is_dead or not has_node("HurtBox"):
		return
	for body in $HurtBox.get_overlapping_bodies():
		_damage_attack_body(body)


func _damage_attack_body(body: Node2D) -> void:
	if is_dead or pulse_state != &"attack":
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
