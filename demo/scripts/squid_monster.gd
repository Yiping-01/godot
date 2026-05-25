extends CharacterBody2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")
const GRAVITY := 900.0
const STATE_IDLE := 0
const STATE_MOVE_ABOVE := 1
const STATE_SLAM := 2
const STATE_RETURN := 3
const STATE_COOLDOWN := 4

@export var detect_range := 300.0
@export var hp := 4
@export var damage := 2
@export var cooldown_time := 2.0
@export var move_above_speed := 520.0
@export var return_speed := 620.0
@export var slam_speed := 900.0
@export var above_player_height := 180.0
@export var hurt_flash_time := 0.15
@export var patrol_speed := 80.0
@export var patrol_distance := 180.0
@export var visual_smoothing := 0.18

@onready var attack_area: Area2D = $AttackArea
@onready var hurt_box: Area2D = $HurtBox
@onready var contact_damage_area: Area2D = get_node_or_null("ContactDamageArea") as Area2D
@onready var sprite: Sprite2D = $Sprite2D

var player: Node2D
var can_attack := true
var has_hit_player := false
var state := STATE_IDLE
var home_position := Vector2.ZERO
var patrol_direction := -1
var start_position := Vector2.ZERO
var slam_target_position := Vector2.ZERO
var hurt_tween: Tween
var hover_time := 0.0
var visual_home_offset := Vector2.ZERO


func _ready() -> void:
	home_position = global_position
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player") as Node2D
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	if contact_damage_area != null:
		contact_damage_area.area_entered.connect(_on_contact_damage_area_entered)
		contact_damage_area.monitoring = true
		call_deferred("_damage_current_contact_overlaps")
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	attack_area.monitoring = false
	visual_home_offset = sprite.position


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player != null and can_attack and state == STATE_IDLE:
		var distance := global_position.distance_to(player.global_position)
		if distance <= detect_range:
			start_slam_attack()

	match state:
		STATE_IDLE:
			_update_idle(delta)
		STATE_MOVE_ABOVE:
			_update_move_above(delta)
		STATE_SLAM:
			_update_slam(delta)
		STATE_RETURN:
			_update_return(delta)


func _update_idle(delta: float) -> void:
	hover_time += delta
	var left_edge := home_position.x - patrol_distance
	var right_edge := home_position.x + patrol_distance

	if global_position.x <= left_edge:
		patrol_direction = 1
	elif global_position.x >= right_edge:
		patrol_direction = -1

	var next_position := global_position
	next_position.x += patrol_direction * patrol_speed * delta
	next_position.x = clampf(next_position.x, left_edge, right_edge)
	next_position.y = home_position.y + sin(hover_time * 2.2) * 7.0
	global_position = global_position.lerp(next_position, clampf(1.0 - pow(visual_smoothing, delta * 60.0), 0.0, 1.0))
	global_position = global_position.round()
	velocity = Vector2.ZERO
	sprite.flip_h = patrol_direction < 0
	sprite.position = visual_home_offset + Vector2(0.0, sin(hover_time * 3.4) * 2.0)


func start_slam_attack() -> void:
	if player == null:
		return

	state = STATE_MOVE_ABOVE
	can_attack = false
	has_hit_player = false
	start_position = global_position
	slam_target_position = Vector2(player.global_position.x, player.global_position.y - above_player_height)
	attack_area.set_deferred("monitoring", false)
	sprite.flip_h = player.global_position.x < global_position.x


func _update_move_above(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = global_position.move_toward(slam_target_position, move_above_speed * delta)
	global_position = global_position.round()

	if global_position.distance_to(slam_target_position) <= 8.0:
		global_position = slam_target_position
		state = STATE_SLAM
		attack_area.set_deferred("monitoring", true)


func _update_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position.y += slam_speed * delta
	global_position = global_position.round()
	_damage_overlapping_players()

	if global_position.y >= start_position.y:
		global_position.y = start_position.y
		start_return()


func start_return() -> void:
	state = STATE_RETURN
	velocity = Vector2.ZERO
	attack_area.set_deferred("monitoring", false)


func _update_return(delta: float) -> void:
	velocity = Vector2.ZERO
	global_position = global_position.move_toward(start_position, return_speed * delta)
	global_position = global_position.round()

	if global_position.distance_to(start_position) <= 8.0:
		global_position = start_position
		velocity = Vector2.ZERO
		start_cooldown()


func start_cooldown() -> void:
	state = STATE_COOLDOWN
	velocity = Vector2.ZERO

	await get_tree().create_timer(cooldown_time).timeout
	can_attack = true
	state = STATE_IDLE


func _on_attack_area_body_entered(body: Node2D) -> void:
	if state != STATE_SLAM or has_hit_player:
		return

	if body.is_in_group("player"):
		has_hit_player = true
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)


func _damage_overlapping_players() -> void:
	if has_hit_player:
		return

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			has_hit_player = true
			if body.has_method("take_damage"):
				body.take_damage(damage, global_position)
			return


func _on_contact_damage_area_entered(area: Area2D) -> void:
	if hp <= 0:
		return
	_damage_contact_target(area)


func _damage_current_contact_overlaps() -> void:
	if hp <= 0 or contact_damage_area == null:
		return
	for area in contact_damage_area.get_overlapping_areas():
		_damage_contact_target(area)


func _damage_contact_target(area: Area2D) -> void:
	var receiver := _find_damage_receiver(area)
	if receiver == null:
		return
	receiver.call("take_damage", damage, global_position)


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.name == "AttackArea" or area.name == "UpAttackArea" or area.name == "DownAttackArea" or area.name == "ChargeAttackArea":
		var attacker := area.get_parent()
		var attacker_position := global_position
		if attacker is Node2D:
			attacker_position = attacker.global_position
		take_damage(1, attacker_position)


func _find_damage_receiver(target_node: Node) -> Node:
	var current: Node = target_node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func take_damage(amount: int, _attacker_position := Vector2.ZERO) -> void:
	hp -= amount
	_flash_hurt()
	DEMO_COMBAT_JUICE.play_hit_pause(self, 0.04, 0.1)

	if hp <= 0:
		_die()


func _die() -> void:
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 1
	if attack_area != null:
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)
	if contact_damage_area != null:
		contact_damage_area.set_deferred("monitoring", false)
		contact_damage_area.set_deferred("monitorable", false)
	if hurt_box != null:
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)

	await _fade_out_death(sprite, 0.45)
	queue_free()


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


func _flash_hurt() -> void:
	if hurt_tween != null:
		hurt_tween.kill()

	sprite.modulate = Color(1.0, 0.2, 0.2)
	hurt_tween = create_tween()
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, hurt_flash_time)
