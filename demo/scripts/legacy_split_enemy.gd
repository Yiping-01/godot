extends CharacterBody2D

const PLAYER_BODY_COLLISION_LAYER_NUMBER := 2

@export var hp := 3
@export var damage := 1
@export var speed := 80.0
@export var patrol_distance := 120.0
@export var knockback_force := 350.0
@export var knockback_friction := 1600.0
@export var hurt_flash_time := 0.15
@export var death_fade_time := 0.45
@export var can_split := false
@export var small_enemy_scene: PackedScene
@export var small_enemy_scene_path := "res://demo/scenes/enemy.tscn"
@export var respawn_scene_path := "res://demo/scenes/legacy_split_enemy.tscn"
@export var spawn_protection_time := 0.35
@export var detection_range := 180.0
@export var attack_range := 120.0
@export var attack_windup_time := 0.3
@export var attack_active_time := 0.24
@export var attack_recovery_time := 0.55
@export var attack_cooldown := 0.9
@export var attack_speed := 260.0
@export var monster_id: String = "WaterBlueBounceOctopus"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var direction := -1
var start_position := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var hurt_tween: Tween
var can_take_damage := true
var is_dead := false
var target: Node2D
var state := &"patrol"
var state_timer := 0.0
var attack_cooldown_left := 0.0
var attack_direction := -1


func _ready() -> void:
	start_position = global_position
	set_collision_mask_value(PLAYER_BODY_COLLISION_LAYER_NUMBER, false)
	add_to_group("enemy")
	anim.play("walk")
	anim.flip_h = direction > 0
	$HurtBox.area_entered.connect(_on_hurtbox_area_entered)
	$HurtBox.body_entered.connect(_on_hurtbox_body_entered)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_target()
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if knockback_velocity.length() > 5.0:
		velocity.x = knockback_velocity.x
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		_update_combat_state(delta)

	move_and_slide()
	_keep_inside_patrol_range()

	if is_on_wall():
		_turn_around()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not can_take_damage:
		return

	if area.name == "AttackArea" or area.name == "UpAttackArea" or area.name == "DownAttackArea" or area.name == "ChargeAttackArea":
		var attacker := area.get_parent()
		if attacker is Node2D:
			take_damage(1, attacker.global_position)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if state != &"attack":
		return
	_damage_attack_body(body)


func take_damage(amount: int, attacker_position: Vector2) -> void:
	if is_dead or not can_take_damage:
		return

	hp -= amount

	if global_position.x > attacker_position.x:
		knockback_velocity = Vector2(knockback_force, 0.0)
	else:
		knockback_velocity = Vector2(-knockback_force, 0.0)

	_cancel_attack()
	_flash_hurt()

	if hp <= 0:
		_die()


func _die() -> void:
	is_dead = true
	_unlock_kill_achievement()
	can_take_damage = false
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 1
	if has_node("HurtBox"):
		$HurtBox.set_deferred("monitoring", false)
		$HurtBox.set_deferred("monitorable", false)

	if can_split:
		call_deferred("split")

	await _fade_out_death(anim, death_fade_time)
	queue_free()


func _unlock_kill_achievement() -> void:
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_method("unlock_kill_achievement"):
		achievement_manager.call("unlock_kill_achievement", monster_id)


func _fade_out_death(target: CanvasItem, duration: float) -> void:
	if target == null:
		return

	target.material = null
	target.modulate = Color(1.0, 0.35, 0.28, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", target.scale * 0.82, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished


func split() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var scene := small_enemy_scene
	if scene == null:
		scene = load(small_enemy_scene_path)

	if scene == null:
		return

	var launch_directions := [-1, 1, 1]
	for i in range(3):
		var small := scene.instantiate()
		var launch_direction: int = launch_directions[i]
		if i == 1:
			launch_direction = -direction
		var spawn_position := global_position + Vector2(float(launch_direction) * randf_range(34.0, 74.0), randf_range(-34.0, -12.0))
		if small is Node2D:
			if parent is Node2D:
				small.position = (parent as Node2D).to_local(spawn_position)
			else:
				small.global_position = spawn_position

		parent.add_child(small)
		if small.has_method("start_spawn_protection"):
			small.start_spawn_protection()
		if small.has_method("launch_from_split"):
			small.launch_from_split(launch_direction, randf_range(320.0, 430.0), 0.38)
		elif small.has_method("set_direction"):
			small.set_direction(launch_direction)


func start_spawn_protection() -> void:
	can_take_damage = false


func finish_spawn_protection() -> void:
	await get_tree().create_timer(spawn_protection_time).timeout
	can_take_damage = true


func set_direction(new_direction: int) -> void:
	direction = new_direction
	if anim != null:
		anim.flip_h = direction > 0


func _turn_around_at_patrol_edge() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x <= left_edge:
		direction = 1
	elif global_position.x >= right_edge:
		direction = -1

	anim.flip_h = direction > 0


func _turn_around() -> void:
	direction *= -1
	anim.flip_h = direction > 0


func _update_target() -> void:
	if target != null and is_instance_valid(target):
		return

	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		target = player


func _update_combat_state(delta: float) -> void:
	match state:
		&"attack_windup":
			_update_attack_windup(delta)
		&"attack":
			_update_attack(delta)
		&"attack_recovery":
			_update_attack_recovery(delta)
		_:
			_update_patrol()


func _update_patrol() -> void:
	if _can_begin_attack():
		_begin_attack_windup()
		return

	anim.modulate = Color.WHITE
	_turn_around_at_patrol_edge()
	velocity.x = direction * speed


func _update_attack_windup(delta: float) -> void:
	velocity.x = 0.0
	state_timer -= delta
	var progress := 1.0 - state_timer / maxf(attack_windup_time, 0.001)
	anim.modulate = Color(1.0, 0.82 + 0.18 * progress, 0.55 + 0.25 * progress, 1.0)
	if state_timer > 0.0:
		return

	state = &"attack"
	state_timer = attack_active_time
	velocity.x = float(attack_direction) * attack_speed
	call_deferred("_damage_current_attack_overlaps")


func _update_attack(delta: float) -> void:
	velocity.x = float(attack_direction) * attack_speed
	state_timer -= delta
	if state_timer > 0.0:
		return

	state = &"attack_recovery"
	state_timer = attack_recovery_time
	velocity.x = 0.0
	anim.modulate = Color.WHITE


func _update_attack_recovery(delta: float) -> void:
	velocity.x = 0.0
	state_timer -= delta
	if state_timer > 0.0:
		return

	state = &"patrol"


func _can_begin_attack() -> bool:
	if target == null or not is_instance_valid(target) or attack_cooldown_left > 0.0:
		return false

	var offset := target.global_position - global_position
	if absf(offset.y) > 96.0:
		return false
	if absf(offset.x) > detection_range:
		return false
	if absf(offset.x) > attack_range and signf(offset.x) != float(direction):
		return false
	return true


func _begin_attack_windup() -> void:
	if target != null and is_instance_valid(target):
		var offset_x := target.global_position.x - global_position.x
		if not is_zero_approx(offset_x):
			direction = int(signf(offset_x))

	attack_direction = direction
	attack_cooldown_left = attack_cooldown
	state = &"attack_windup"
	state_timer = attack_windup_time
	velocity.x = 0.0
	anim.flip_h = direction > 0


func _cancel_attack() -> void:
	state = &"patrol"
	state_timer = 0.0
	anim.modulate = Color.WHITE


func _damage_current_attack_overlaps() -> void:
	if state != &"attack" or not has_node("HurtBox"):
		return
	for body in $HurtBox.get_overlapping_bodies():
		_damage_attack_body(body)


func _damage_attack_body(body: Node2D) -> void:
	if state != &"attack":
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)


func _keep_inside_patrol_range() -> void:
	var left_edge := start_position.x - patrol_distance
	var right_edge := start_position.x + patrol_distance

	if global_position.x < left_edge:
		global_position.x = left_edge
		knockback_velocity.x = maxf(knockback_velocity.x, 0.0)
	elif global_position.x > right_edge:
		global_position.x = right_edge
		knockback_velocity.x = minf(knockback_velocity.x, 0.0)


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	anim.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(anim, "modulate", Color.WHITE, hurt_flash_time)
