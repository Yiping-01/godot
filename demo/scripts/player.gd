extends CharacterBody2D
class_name PlayerController

signal health_changed(current_health: float, max_health: int)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal died
signal respawned

@export_category("Health")
@export var max_health: int = 5
@export var invincible_time: float = 1.0
@export var knockback_force: float = 420.0
@export var knockback_up_velocity: float = -260.0
@export var hurt_control_lock_time: float = 0.18
@export var hurt_animation_time: float = 0.25
@export var respawn_delay: float = 1.35
@export var health_potion_heal_amount: float = 0.5

@export_category("Movement")
@export var speed: float = 390.0
@export var jump_velocity: float = -575.0
@export var jump_cut_multiplier: float = 0.55
@export var jump_gravity: float = 1200.0
@export var fall_gravity: float = 1700.0
@export var max_fall_speed: float = 600.0
@export var max_jump_count: int = 2
@export var wall_slide_speed: float = 150.0
@export var wall_jump_velocity: float = -500.0
@export var wall_jump_push_velocity: float = 430.0
@export var wall_jump_lock_time: float = 0.15
@export var wall_jump_surface_group := "wall_jump_surface"
@export var dash_speed: float = 860.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.34
@export var dash_trail_interval: float = 0.045
@export var max_stamina: float = 100.0
@export var dash_stamina_cost: float = 22.0
@export var stamina_recovery_rate: float = 44.0
@export var stamina_recovery_delay: float = 2.0
@export var underwater_swim_speed: float = 335.0
@export var underwater_swim_acceleration: float = 1700.0
@export var underwater_drag: float = 1050.0
@export var underwater_dash_speed: float = 720.0
@export var underwater_dash_duration: float = 0.24
@export var underwater_wall_dash_speed: float = 900.0
@export var underwater_wall_dash_duration: float = 0.34
@export var underwater_dash_cooldown: float = 0.34
@export var water_surface_jump_margin: float = 58.0
@export var water_surface_exit_lift: float = 28.0
@export var water_exit_animation_time: float = 0.36
@export var double_jump_animation_time: float = 0.28
@export var water_exit_camera_smoothing_speed: float = 4.0
@export var water_exit_camera_blend_time: float = 0.45

@export_category("Combat")
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.3
@export var combo_reset_time: float = 0.5
@export var attack_active_time: float = 0.14
@export var recoil_velocity: float = 180.0
@export var down_recoil_velocity: float = 560.0
@export var charge_hold_time: float = 0.65
@export var charge_attack_damage: int = 3
@export var charge_attack_active_time: float = 0.22
@export var charge_attack_cooldown: float = 0.55
@export var charge_recoil_velocity: float = 260.0
@export var charge_move_speed_multiplier: float = 0.45
@export var far_attack_damage: int = 1
@export var far_attack_speed: float = 500.0
@export var far_attack_duration: float = 0.3
@export var far_attack_hit_radius: float = 22.0
@export var far_attack_effect_scale := Vector2(0.2, 0.2)
@export var far_attack_cooldown: float = 3.0
@export var ultimate_hold_time: float = 0.55
@export var ultimate_default_damage: int = 4
@export var ultimate_default_radius: float = 190.0

@export_category("Camera")
@export var camera_follow_position := Vector2(80.0, -40.0)
@export var camera_follow_zoom := Vector2(1.2, 1.2)
@export var camera_follow_smoothing_speed: float = 8.0
@export var use_map_wall_camera_limits := true

@export_category("Lighting")
@export var enable_player_light := true
@export var scene_darkness := Color(0.84, 0.86, 0.90, 1.0)
@export var player_light_radius: float = 250.0
@export var player_light_energy: float = 0.36
@export var player_light_color := Color(0.74, 0.92, 1.0, 1.0)

const CAMERA_UNBOUNDED_LIMIT := 10000000
const FAR_ATTACK_TEXTURES: Array[Texture2D] = [
	preload("res://demo/assets/art/legacy/player/attack_far/far_1.png"),
	preload("res://demo/assets/art/legacy/player/attack_far/far_2.png"),
	preload("res://demo/assets/art/legacy/player/attack_far/far_3.png"),
	preload("res://demo/assets/art/legacy/player/attack_far/far_4.png"),
	preload("res://demo/assets/art/legacy/player/attack_far/far_5.png"),
]
const FAR_ATTACK_PROJECTILE := preload("res://demo/scripts/far_attack_projectile.gd")
const CUSTOM_2D_LIGHT_SHADER := preload("res://demo/shaders/shaderlib/custom_2d_light.gdshader")
const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")
const WATER_EXIT_PARTICLE_TEXTURE := preload("res://demo/assets/hollow_import/effects/water_footstep_particle.png")
const AIR_JUMP_PARTICLE_TEXTURE := preload("res://demo/assets/hollow_import/effects/white_hit_particle.png")
const ULTIMATE_COMBOS := {
	"quick_map|wall_burst": {"name": "潮汐破圖", "damage": 4, "radius": 220.0, "color": Color(0.72, 1.0, 0.95, 1.0), "rays": 10},
	"quick_map|water_dash": {"name": "流光穿梭", "damage": 4, "radius": 230.0, "color": Color(0.58, 0.9, 1.0, 1.0), "rays": 12},
	"quick_map|water_shot": {"name": "星圖水槍", "damage": 5, "radius": 190.0, "color": Color(0.85, 0.96, 1.0, 1.0), "rays": 14},
	"wall_burst|water_dash": {"name": "裂牆湧流", "damage": 5, "radius": 210.0, "color": Color(0.48, 1.0, 0.86, 1.0), "rays": 12},
	"wall_burst|water_shot": {"name": "碎岩水炮", "damage": 6, "radius": 180.0, "color": Color(1.0, 0.88, 0.46, 1.0), "rays": 16},
	"water_dash|water_shot": {"name": "深潮爆發", "damage": 5, "radius": 220.0, "color": Color(0.38, 0.82, 1.0, 1.0), "rays": 14},
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var up_attack_area: Area2D = $UpAttackArea
@onready var up_attack_shape: CollisionShape2D = $UpAttackArea/CollisionShape2D
@onready var down_attack_area: Area2D = $DownAttackArea
@onready var down_attack_shape: CollisionShape2D = $DownAttackArea/CollisionShape2D
@onready var charge_attack_area: Area2D = $ChargeAttackArea
@onready var charge_attack_shape: CollisionShape2D = $ChargeAttackArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var attack_effect: AnimatedSprite2D = $AttackEffect
@onready var charge_effect: AnimatedSprite2D = $ChargeEffect
@onready var hit_effect: AnimatedSprite2D = $HitEffect
@onready var death_effect: AnimatedSprite2D = $DeathEffect
@onready var jump_audio: AudioStreamPlayer2D = $JumpAudio
@onready var double_jump_audio: AudioStreamPlayer2D = $DoubleJumpAudio
@onready var attack_audio: AudioStreamPlayer2D = $AttackAudio
@onready var far_attack_audio: AudioStreamPlayer2D = $FarAttackAudio
@onready var hit_audio: AudioStreamPlayer2D = $HitAudio
@onready var hurt_audio: AudioStreamPlayer2D = $HurtAudio

var current_health: float = 0.0
var invincible := false
var is_dead := false
var hurt_lock_left := 0.0
var hurt_animation_left := 0.0
var is_hurt_animating := false
var knockback_velocity := Vector2.ZERO
var respawn_position := Vector2.ZERO
var camera_base_offset := Vector2.ZERO
var default_camera_position := Vector2.ZERO
var default_camera_offset := Vector2.ZERO
var default_camera_zoom := Vector2.ONE
var default_camera_smoothing_speed := 8.0
var manual_camera_limits_enabled := false
var manual_camera_limit_left := -CAMERA_UNBOUNDED_LIMIT
var manual_camera_limit_top := -CAMERA_UNBOUNDED_LIMIT
var manual_camera_limit_right := CAMERA_UNBOUNDED_LIMIT
var manual_camera_limit_bottom := CAMERA_UNBOUNDED_LIMIT
var shake_time_left := 0.0
var shake_strength := 0.0

var facing_direction := -1
var jump_count := 0
var attack_time_left := 0.0
var last_attack_time := -999.0
var last_attack_cooldown := 0.0
var combo_count := 0
var attack_offset_x := 0.0
var charge_attack_offset_x := 0.0
var current_attack_damage := 0
var hit_targets := {}
var is_attacking := false
var active_attack_area: Area2D
var active_attack_shape: CollisionShape2D
var active_attack_type := &"side"
var wall_jump_lock_left := 0.0
var is_charging_attack := false
var attack_charge_time := 0.0
var charge_ready := false
var is_dashing := false
var dash_time_left := 0.0
var dash_trail_time_left := 0.0
var dash_cooldown_left := 0.0
var current_stamina := 100.0
var stamina_recovery_delay_left := 0.0
var far_attack_cooldown_left := 0.0
var far_attack_holding := false
var far_attack_hold_time := 0.0
var dash_direction := 1
var is_underwater := false
var has_water_surface_y := false
var water_surface_y := 0.0
var underwater_dash_direction := Vector2.ZERO
var underwater_dash_current_speed := 0.0
var water_exit_animation_left := 0.0
var double_jump_animation_left := 0.0
var water_exit_camera_blend_left := 0.0
var is_resting := false
var normal_z_index := 0
var attack_effect_base_scale := Vector2.ONE
var charge_effect_base_scale := Vector2.ONE
var far_attack_frames: SpriteFrames


func _ready() -> void:
	_play_game_music()
	if GameState.has_player_runtime_status():
		current_health = clampf(GameState.player_current_health, 0.0, float(max_health))
		current_stamina = clampf(GameState.player_current_stamina, 0.0, max_stamina)
	else:
		current_health = float(max_health)
		current_stamina = max_stamina
	respawn_position = _get_spawn_position()
	global_position = respawn_position
	camera_base_offset = camera.offset
	default_camera_position = camera_follow_position
	default_camera_offset = camera.offset
	default_camera_zoom = camera_follow_zoom
	default_camera_smoothing_speed = camera_follow_smoothing_speed
	_configure_follow_camera()
	call_deferred("_snap_camera_to_player")
	_setup_player_light()
	normal_z_index = z_index
	attack_offset_x = absf(attack_area.position.x)
	charge_attack_offset_x = absf(charge_attack_area.position.x)
	current_attack_damage = attack_damage
	last_attack_cooldown = attack_cooldown
	attack_effect_base_scale = attack_effect.scale
	charge_effect_base_scale = charge_effect.scale
	far_attack_frames = _build_far_attack_frames()
	active_attack_area = attack_area
	active_attack_shape = attack_shape
	_set_all_attack_areas_enabled(false)
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	attack_effect.animation_finished.connect(_on_attack_effect_animation_finished)
	charge_effect.animation_finished.connect(_on_charge_effect_animation_finished)
	hit_effect.animation_finished.connect(_on_hit_effect_animation_finished)
	death_effect.animation_finished.connect(_on_death_effect_animation_finished)
	attack_effect.visible = false
	charge_effect.visible = false
	hit_effect.visible = false
	death_effect.visible = false
	animated_sprite.flip_h = facing_direction > 0
	_update_attack_area_side()
	animated_sprite.play("wait")
	_sync_runtime_status()
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)


func _physics_process(delta: float) -> void:
	if is_dead:
		_update_camera_shake(delta)
		return

	_update_stamina(delta)

	if far_attack_cooldown_left > 0.0:
		far_attack_cooldown_left = maxf(far_attack_cooldown_left - delta, 0.0)
	_update_hurt_animation_state(delta)
	_update_motion_animation_timers(delta)

	if is_resting:
		_cancel_attack_charge()
		_end_dash(false)
		velocity = Vector2.ZERO
		_update_camera_shake(delta)
		return

	if GameState.input_locked:
		_cancel_attack_charge()
		_end_dash(false)
		if is_underwater:
			velocity = velocity.move_toward(Vector2.ZERO, underwater_drag * delta)
		else:
			if is_on_floor() and velocity.y >= 0.0:
				jump_count = 0
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, speed * delta * 6.0)
		move_and_slide()
		_update_animation()
		_update_camera_shake(delta)
		return

	if is_underwater:
		_update_underwater_movement(delta)
		return

	if is_on_floor() and velocity.y >= 0.0:
		jump_count = 0

	_update_dash_cooldown(delta)
	_handle_dash_input()
	if is_dashing:
		_update_dash(delta)
		_update_attack(delta)
		move_and_slide()
		_update_animation()
		_update_camera_shake(delta)
		return

	_apply_gravity(delta)
	_update_wall_slide()
	_handle_movement(delta)
	_handle_jump()
	_handle_far_attack_input(delta)
	_handle_attack_input(delta)
	_update_attack(delta)

	move_and_slide()
	_update_animation()
	_update_camera_shake(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_group_switch") and not GameState.input_locked and not is_dead:
		GameState.toggle_active_skill_group()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and _try_use_health_potion():
		get_viewport().set_input_as_handled()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y > 0.0:
			velocity.y = 0.0
		return

	var gravity := jump_gravity if velocity.y < 0.0 else fall_gravity
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _handle_movement(delta: float) -> void:
	if hurt_lock_left > 0.0:
		hurt_lock_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, knockback_force * delta * 2.5)
		return

	if wall_jump_lock_left > 0.0:
		wall_jump_lock_left -= delta
		return

	var input_direction := _get_horizontal_input()
	var move_speed := speed
	if is_charging_attack:
		move_speed *= charge_move_speed_multiplier

	velocity.x = input_direction * move_speed

	if not is_zero_approx(input_direction):
		facing_direction = int(signf(input_direction))
		# The current player art faces left by default, so flip only when facing right.
		animated_sprite.flip_h = facing_direction > 0
		_update_attack_area_side()


func _update_underwater_movement(delta: float) -> void:
	jump_count = 0
	wall_jump_lock_left = 0.0
	_update_dash_cooldown(delta)
	if _try_water_surface_jump():
		_apply_gravity(delta)
		_handle_movement(delta)
		move_and_slide()
		_update_animation()
		_update_camera_shake(delta)
		return
	_handle_underwater_dash_input()
	if is_dashing:
		_update_underwater_dash(delta)
		_update_attack(delta)
		move_and_slide()
		_update_animation()
		_update_camera_shake(delta)
		return

	_handle_underwater_swim(delta)
	_handle_far_attack_input(delta)
	_handle_underwater_attack_input()
	_update_attack(delta)

	move_and_slide()
	_update_animation()
	_update_camera_shake(delta)


func _handle_underwater_swim(delta: float) -> void:
	if hurt_lock_left > 0.0:
		hurt_lock_left -= delta
		velocity = velocity.move_toward(Vector2.ZERO, underwater_drag * delta * 0.55)
		return

	var input_vector := _get_underwater_input()
	var move_speed := underwater_swim_speed
	if is_charging_attack:
		move_speed *= charge_move_speed_multiplier

	if input_vector == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, underwater_drag * delta)
	else:
		velocity = velocity.move_toward(input_vector * move_speed, underwater_swim_acceleration * delta)
		if not is_zero_approx(input_vector.x):
			facing_direction = int(signf(input_vector.x))
			animated_sprite.flip_h = facing_direction > 0
			_update_attack_area_side()


func _try_water_surface_jump() -> bool:
	if hurt_lock_left > 0.0 or is_hurt_animating or is_attacking or is_dashing or is_charging_attack:
		return false
	if not Input.is_action_just_pressed("jump"):
		return false
	if not has_water_surface_y:
		return false
	if global_position.y > water_surface_y + water_surface_jump_margin:
		return false

	is_underwater = false
	global_position.y = water_surface_y - water_surface_exit_lift
	velocity.y = jump_velocity
	velocity.x = _get_horizontal_input() * speed
	jump_count = 1
	wall_jump_lock_left = 0.0
	underwater_dash_direction = Vector2.ZERO
	underwater_dash_current_speed = 0.0
	_start_water_exit_animation()
	_play_audio(jump_audio)
	return true


func _handle_underwater_dash_input() -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating or is_attacking or is_charging_attack or dash_cooldown_left > 0.0:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	if not _try_spend_dash_stamina():
		return

	var input_vector := _get_underwater_input()
	var wall_normal := _get_underwater_wall_normal()
	var is_wall_dash := not is_zero_approx(wall_normal.x)
	if input_vector == Vector2.ZERO:
		input_vector = Vector2(float(facing_direction), 0.0)
	if is_wall_dash:
		var wall_away_direction := signf(wall_normal.x)
		if is_zero_approx(input_vector.x) or signf(input_vector.x) != wall_away_direction:
			input_vector = Vector2(wall_away_direction, input_vector.y).normalized()

	underwater_dash_direction = input_vector.normalized()
	if is_wall_dash:
		underwater_dash_current_speed = underwater_wall_dash_speed
		dash_time_left = underwater_wall_dash_duration
	else:
		underwater_dash_current_speed = underwater_dash_speed
		dash_time_left = underwater_dash_duration

	if not is_zero_approx(underwater_dash_direction.x):
		facing_direction = int(signf(underwater_dash_direction.x))
		animated_sprite.flip_h = facing_direction > 0
		_update_attack_area_side()

	is_dashing = true
	dash_trail_time_left = 0.0
	dash_cooldown_left = underwater_dash_cooldown
	velocity = underwater_dash_direction * underwater_dash_current_speed
	_play_dash_animation(underwater_dash_direction)


func _update_underwater_dash(delta: float) -> void:
	dash_time_left -= delta
	velocity = underwater_dash_direction * underwater_dash_current_speed
	_update_dash_trail(delta, underwater_dash_direction)
	if dash_time_left <= 0.0:
		_end_dash(true)


func _handle_jump() -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating:
		return

	if Input.is_action_just_pressed("jump") and _can_wall_jump():
		_do_wall_jump()
		return

	if Input.is_action_just_pressed("jump") and (is_on_floor() or jump_count < max_jump_count):
		jump_count += 1
		velocity.y = jump_velocity
		if jump_count == 1:
			_play_audio(jump_audio)
		else:
			_start_double_jump_animation()
			_play_audio(double_jump_audio)

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _handle_attack_input(delta: float) -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating:
		_cancel_attack_charge()
		return

	if Input.is_action_just_pressed("attack") and Input.is_action_pressed("move_down") and not is_on_floor():
		_cancel_attack_charge()
		_try_attack()
		return

	if Input.is_action_just_pressed("attack"):
		_begin_attack_charge()

	if not is_charging_attack:
		return

	_set_all_attack_areas_enabled(false)
	attack_charge_time += delta
	if not charge_ready and attack_charge_time >= charge_hold_time:
		charge_ready = true
		_show_charge_ready_effect()
	elif charge_ready:
		_update_charge_ready_effect()

	if Input.is_action_just_released("attack"):
		if charge_ready:
			_try_charge_attack()
		else:
			_try_attack()
		_cancel_attack_charge()


func _handle_underwater_attack_input() -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating:
		_cancel_attack_charge()
		return

	if Input.is_action_just_pressed("attack"):
		_cancel_attack_charge()
		_try_attack()


func _handle_far_attack_input(delta: float) -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating or is_attacking or is_dashing or is_charging_attack:
		_cancel_far_attack_hold()
		return

	if Input.is_action_just_pressed("far_attack"):
		far_attack_holding = true
		far_attack_hold_time = 0.0

	if not far_attack_holding:
		return

	if Input.is_action_pressed("far_attack"):
		far_attack_hold_time += delta
		if far_attack_hold_time >= ultimate_hold_time and GameState.is_ultimate_ready():
			_cancel_far_attack_hold()
			_try_ultimate_attack()
		return

	if Input.is_action_just_released("far_attack"):
		_cancel_far_attack_hold()
		_try_far_attack()


func _cancel_far_attack_hold() -> void:
	far_attack_holding = false
	far_attack_hold_time = 0.0


func _try_attack() -> void:
	if is_attacking or is_dashing:
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if now < last_attack_time + last_attack_cooldown:
		return

	if now >= last_attack_time + combo_reset_time:
		combo_count = 0

	combo_count = (combo_count % 2) + 1
	last_attack_time = now
	last_attack_cooldown = attack_cooldown
	attack_time_left = attack_active_time
	active_attack_type = _get_attack_type()
	current_attack_damage = attack_damage
	hit_targets.clear()
	is_attacking = true
	_select_attack_area(active_attack_type)
	_set_active_attack_enabled(true)
	_play_attack_effect(active_attack_type)
	_play_audio(attack_audio)
	_play_player_attack_animation(active_attack_type)


func _try_far_attack() -> void:
	if is_attacking or is_dashing or far_attack_cooldown_left > 0.0:
		return

	var input_direction := _get_horizontal_input()
	if not is_zero_approx(input_direction):
		facing_direction = int(signf(input_direction))
		animated_sprite.flip_h = facing_direction > 0
		_update_attack_area_side()

	is_attacking = true
	far_attack_cooldown_left = far_attack_cooldown
	active_attack_type = &"far"
	_spawn_far_attack_projectile()
	_play_audio(far_attack_audio)
	_play_player_attack_animation(&"side")


func _try_ultimate_attack() -> void:
	if is_attacking or is_dashing or not GameState.consume_ultimate_charge():
		return

	var config := _get_ultimate_config()
	var radius := float(config.get("radius", ultimate_default_radius))
	var damage := int(config.get("damage", ultimate_default_damage))
	var effect_color: Color = config.get("color", Color(0.7, 0.95, 1.0, 1.0))
	var hit_count := 0

	for receiver in get_tree().get_nodes_in_group("enemy"):
		if receiver == null or receiver == self or not receiver.has_method("take_damage"):
			continue
		if not receiver is Node2D:
			continue
		if global_position.distance_to((receiver as Node2D).global_position) > radius:
			continue
		receiver.call("take_damage", damage, global_position)
		hit_count += 1

	if hit_count > 0:
		_play_audio(hit_audio)
	_spawn_ultimate_effect(radius, effect_color, int(config.get("rays", 12)))
	_start_camera_shake(0.36, 12.0)
	DEMO_COMBAT_JUICE.play_hit_pause(self, 0.09, 0.22)
	_play_player_attack_animation(&"side")


func _get_ultimate_config() -> Dictionary:
	var combo_key := _active_ultimate_key()
	if ULTIMATE_COMBOS.has(combo_key):
		return ULTIMATE_COMBOS[combo_key]
	return {
		"name": "深海爆發",
		"damage": ultimate_default_damage,
		"radius": ultimate_default_radius,
		"color": Color(0.68, 0.92, 1.0, 1.0),
		"rays": 10,
	}


func _active_ultimate_key() -> String:
	var ids := GameState.get_active_skill_ids()
	var valid_ids: Array[String] = []
	for id in ids:
		var skill_id := String(id)
		if skill_id != "":
			valid_ids.append(skill_id)
	valid_ids.sort()
	return "|".join(valid_ids)


func _spawn_ultimate_effect(radius: float, effect_color: Color, ray_count: int) -> void:
	var root := Node2D.new()
	root.name = "UltimateBurst"
	root.global_position = global_position
	root.z_index = 90
	get_parent().add_child(root)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.0
	ring.default_color = effect_color
	ring.points = _circle_points(radius * 0.2, 56)
	root.add_child(ring)

	var core := Polygon2D.new()
	core.color = Color(effect_color.r, effect_color.g, effect_color.b, 0.32)
	core.polygon = _circle_points(radius * 0.16, 32)
	root.add_child(core)

	for i in range(ray_count):
		var angle := TAU * float(i) / float(maxi(ray_count, 1)) + randf_range(-0.08, 0.08)
		var ray := Line2D.new()
		ray.width = randf_range(2.0, 4.5)
		ray.default_color = Color(effect_color.r, effect_color.g, effect_color.b, 0.75)
		var inner := Vector2(cos(angle), sin(angle)) * radius * randf_range(0.16, 0.3)
		var outer := Vector2(cos(angle), sin(angle)) * radius * randf_range(0.72, 1.05)
		ray.points = PackedVector2Array([inner, outer])
		root.add_child(ray)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "points", _circle_points(radius, 56), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.36).set_delay(0.16)
	tween.tween_property(core, "scale", Vector2.ONE * 3.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(core, "modulate:a", 0.0, 0.32)
	tween.finished.connect(root.queue_free)


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _try_charge_attack() -> void:
	if is_attacking or is_dashing:
		return

	var now := float(Time.get_ticks_msec()) / 1000.0
	if now < last_attack_time + last_attack_cooldown:
		return

	var input_direction := _get_horizontal_input()
	if not is_zero_approx(input_direction):
		facing_direction = int(signf(input_direction))
		animated_sprite.flip_h = facing_direction > 0
		_update_attack_area_side()

	combo_count = 0
	last_attack_time = now
	last_attack_cooldown = charge_attack_cooldown
	attack_time_left = charge_attack_active_time
	active_attack_type = &"charge"
	current_attack_damage = charge_attack_damage
	hit_targets.clear()
	is_attacking = true
	_select_attack_area(active_attack_type)
	_set_active_attack_enabled(true)
	_play_attack_effect(active_attack_type)
	_play_audio(attack_audio)
	_start_camera_shake(0.12, 5.0)
	_play_player_attack_animation(active_attack_type)


func _update_attack(delta: float) -> void:
	if attack_time_left <= 0.0:
		return

	_apply_attack_hits()
	attack_time_left -= delta
	if attack_time_left <= 0.0:
		_set_active_attack_enabled(false)


func _apply_attack_hits() -> void:
	if active_attack_area == null:
		return
	if not active_attack_area.monitoring:
		return

	var targets: Array[Node] = []
	targets.append_array(active_attack_area.get_overlapping_bodies())
	targets.append_array(active_attack_area.get_overlapping_areas())

	for target in targets:
		var receiver: Node = _find_damage_receiver(target)
		if receiver == null or receiver == self:
			continue

		var instance_id: int = int(receiver.get_instance_id())
		if hit_targets.has(instance_id):
			continue

		hit_targets[instance_id] = true
		receiver.call("take_damage", current_attack_damage, global_position)
		if receiver.is_in_group("enemy"):
			GameState.add_ultimate_charge(10.0 if active_attack_type == &"charge" else 7.0)
		_play_audio(hit_audio)
		var hit_position: Vector2 = receiver.global_position if receiver is Node2D else active_attack_area.global_position
		_play_hit_effect(hit_position)
		_start_camera_shake(0.14, 6.0 if active_attack_type == &"charge" else 3.5)
		DEMO_COMBAT_JUICE.play_hit_pause(self)
		DEMO_COMBAT_JUICE.spawn_hit_flash(self, hit_position, facing_direction)
		match active_attack_type:
			&"down":
				velocity.y = -down_recoil_velocity
				jump_count = mini(jump_count, max_jump_count - 1)
			&"charge":
				velocity.x = -facing_direction * charge_recoil_velocity
			_:
				velocity.x = -facing_direction * recoil_velocity


func _find_damage_receiver(target: Node) -> Node:
	var current: Node = target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _build_far_attack_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", 18.0)
	for texture in FAR_ATTACK_TEXTURES:
		frames.add_frame(&"fly", texture)
	return frames


func _spawn_far_attack_projectile() -> void:
	if far_attack_frames == null:
		far_attack_frames = _build_far_attack_frames()

	var projectile := FAR_ATTACK_PROJECTILE.new()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(100.0 * facing_direction, -6.0)
	projectile.setup(
		far_attack_frames,
		facing_direction,
		far_attack_speed,
		far_attack_damage,
		far_attack_duration,
		far_attack_hit_radius,
		far_attack_effect_scale
	)


func _set_all_attack_areas_enabled(enabled: bool) -> void:
	attack_area.set_deferred("monitoring", enabled)
	attack_shape.set_deferred("disabled", not enabled)
	up_attack_area.set_deferred("monitoring", enabled)
	up_attack_shape.set_deferred("disabled", not enabled)
	down_attack_area.set_deferred("monitoring", enabled)
	down_attack_shape.set_deferred("disabled", not enabled)
	charge_attack_area.set_deferred("monitoring", enabled)
	charge_attack_shape.set_deferred("disabled", not enabled)


func _set_active_attack_enabled(enabled: bool) -> void:
	_set_all_attack_areas_enabled(false)
	if enabled and active_attack_area != null and active_attack_shape != null:
		active_attack_area.set_deferred("monitoring", true)
		active_attack_shape.set_deferred("disabled", false)


func _update_attack_area_side() -> void:
	attack_area.position.x = attack_offset_x * facing_direction
	charge_attack_area.position.x = charge_attack_offset_x * facing_direction


func _get_attack_type() -> StringName:
	if Input.is_action_pressed("move_up"):
		return &"up"
	if Input.is_action_pressed("move_down") and not is_on_floor():
		return &"down"
	return &"side"


func _get_horizontal_input() -> float:
	var input_direction: float = 0.0
	if Input.is_action_pressed("move_left"):
		input_direction -= 1.0
	if Input.is_action_pressed("move_right"):
		input_direction += 1.0
	return input_direction


func _get_vertical_input() -> float:
	var input_direction: float = 0.0
	if Input.is_action_pressed("move_up"):
		input_direction -= 1.0
	if Input.is_action_pressed("move_down"):
		input_direction += 1.0
	return input_direction


func _get_underwater_input() -> Vector2:
	var input_vector := Vector2(_get_horizontal_input(), _get_vertical_input())
	if input_vector.length_squared() > 1.0:
		return input_vector.normalized()
	return input_vector


func _is_underwater_wall_swimming() -> bool:
	return not is_zero_approx(_get_underwater_wall_normal().x)


func _get_underwater_wall_normal() -> Vector2:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var normal := collision.get_normal()
		if not is_zero_approx(normal.x):
			return normal

	return Vector2.ZERO


func _update_wall_slide() -> void:
	if not _can_wall_slide():
		return

	velocity.y = minf(velocity.y, wall_slide_speed)
	jump_count = min(max_jump_count - 1, jump_count)


func _can_wall_slide() -> bool:
	if is_on_floor() or not is_on_wall() or velocity.y < 0.0:
		return false

	var wall_normal := _get_wall_jump_surface_normal()
	if is_zero_approx(wall_normal.x):
		return false

	var input_direction := _get_horizontal_input()
	return is_equal_approx(input_direction, -signf(wall_normal.x))


func _can_wall_jump() -> bool:
	return not is_on_floor() and not is_zero_approx(_get_wall_jump_surface_normal().x)


func _do_wall_jump() -> void:
	var wall_normal := _get_wall_jump_surface_normal()
	if is_zero_approx(wall_normal.x):
		wall_normal.x = -float(facing_direction)

	velocity.x = signf(wall_normal.x) * wall_jump_push_velocity
	velocity.y = wall_jump_velocity
	wall_jump_lock_left = wall_jump_lock_time
	jump_count = 1
	facing_direction = int(signf(wall_normal.x))
	animated_sprite.flip_h = facing_direction > 0
	_update_attack_area_side()
	_play_audio(jump_audio)


func _get_wall_jump_surface_normal() -> Vector2:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		var normal := collision.get_normal()
		if is_zero_approx(normal.x):
			continue
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group(wall_jump_surface_group):
			return normal

	return Vector2.ZERO


func _update_dash_cooldown(delta: float) -> void:
	if dash_cooldown_left > 0.0:
		dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)


func _update_stamina(delta: float) -> void:
	if stamina_recovery_delay_left > 0.0:
		stamina_recovery_delay_left = maxf(stamina_recovery_delay_left - delta, 0.0)
		return
	if is_dashing or current_stamina >= max_stamina:
		return
	current_stamina = minf(current_stamina + stamina_recovery_rate * delta, max_stamina)
	_sync_runtime_status()
	stamina_changed.emit(current_stamina, max_stamina)


func _try_spend_dash_stamina() -> bool:
	if current_stamina < dash_stamina_cost:
		return false
	current_stamina = maxf(current_stamina - dash_stamina_cost, 0.0)
	stamina_recovery_delay_left = stamina_recovery_delay
	_sync_runtime_status()
	stamina_changed.emit(current_stamina, max_stamina)
	return true


func _handle_dash_input() -> void:
	if hurt_lock_left > 0.0 or is_hurt_animating or is_attacking or is_charging_attack or dash_cooldown_left > 0.0:
		return
	if not Input.is_action_just_pressed("dash"):
		return
	if not _try_spend_dash_stamina():
		return

	var input_direction := _get_horizontal_input()
	dash_direction = facing_direction
	if not is_zero_approx(input_direction):
		dash_direction = int(signf(input_direction))

	facing_direction = dash_direction
	animated_sprite.flip_h = facing_direction > 0
	_update_attack_area_side()
	is_dashing = true
	dash_time_left = dash_duration
	dash_trail_time_left = 0.0
	dash_cooldown_left = dash_cooldown
	velocity = Vector2(float(dash_direction) * dash_speed, 0.0)
	_play_dash_animation(Vector2(float(dash_direction), 0.0))


func _update_dash(delta: float) -> void:
	dash_time_left -= delta
	velocity = Vector2(float(dash_direction) * dash_speed, 0.0)
	_update_dash_trail(delta, Vector2(float(dash_direction), 0.0))
	if dash_time_left <= 0.0:
		_end_dash(true)


func _end_dash(keep_momentum: bool = true) -> void:
	if not is_dashing:
		return

	is_dashing = false
	dash_time_left = 0.0
	dash_trail_time_left = 0.0
	if keep_momentum:
		velocity.x = float(dash_direction) * speed * 0.65


func _select_attack_area(attack_type: StringName) -> void:
	match attack_type:
		&"up":
			active_attack_area = up_attack_area
			active_attack_shape = up_attack_shape
		&"down":
			active_attack_area = down_attack_area
			active_attack_shape = down_attack_shape
		&"charge":
			_update_attack_area_side()
			active_attack_area = charge_attack_area
			active_attack_shape = charge_attack_shape
		_:
			_update_attack_area_side()
			active_attack_area = attack_area
			active_attack_shape = attack_shape


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or invincible:
		return

	current_health = maxf(current_health - float(amount), 0.0)
	_sync_runtime_status()
	health_changed.emit(current_health, max_health)
	_cancel_attack_state()
	_end_dash(false)
	_cancel_attack_charge()
	_apply_hurt_knockback(from_position)
	_play_audio(hurt_audio)
	_play_hurt_animation()
	_play_hit_effect(global_position)
	_start_camera_shake(0.24, 8.0)

	if current_health <= 0.0:
		die()
		return

	_start_invincibility()


func take_quake_damage(amount: int) -> void:
	if is_dead or invincible:
		return

	current_health = maxf(current_health - float(amount), 0.0)
	_sync_runtime_status()
	health_changed.emit(current_health, max_health)
	_cancel_attack_state()
	_end_dash(false)
	_cancel_attack_charge()
	_play_audio(hurt_audio)
	_play_hurt_animation()
	_play_hit_effect(global_position)

	if current_health <= 0.0:
		die()
		return

	_start_invincibility()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = minf(current_health + amount, float(max_health))
	_sync_runtime_status()
	health_changed.emit(current_health, max_health)


func heal_to_full() -> void:
	if is_dead:
		return

	current_health = float(max_health)
	_sync_runtime_status()
	health_changed.emit(current_health, max_health)


func set_respawn_position(new_position: Vector2) -> void:
	respawn_position = new_position
	GameState.set_respawn_position(new_position)


func face_position(target_position: Vector2) -> void:
	var new_direction := signf(target_position.x - global_position.x)
	if is_zero_approx(new_direction):
		return

	facing_direction = int(new_direction)
	animated_sprite.flip_h = facing_direction > 0
	_update_attack_area_side()


func sit_on_bench(seat_position: Vector2, facing: int = 1) -> void:
	is_resting = true
	_cancel_attack_charge()
	_end_dash(false)
	velocity = Vector2.ZERO
	global_position = seat_position
	z_index = 20
	facing_direction = facing
	animated_sprite.flip_h = facing_direction > 0
	_update_attack_area_side()
	_set_all_attack_areas_enabled(false)
	animated_sprite.play("wait")


func stand_from_bench(stand_position: Vector2) -> void:
	global_position = stand_position
	velocity = Vector2.ZERO
	z_index = normal_z_index
	hurt_lock_left = 0.0
	wall_jump_lock_left = 0.0
	_end_dash(false)
	_cancel_attack_charge()
	jump_count = 0
	is_resting = false
	animated_sprite.play("wait")


func set_underwater(enabled: bool) -> void:
	if is_underwater == enabled:
		return

	is_underwater = enabled
	jump_count = 0
	wall_jump_lock_left = 0.0
	_end_dash(false)
	velocity *= 0.35
	if not enabled:
		dash_cooldown_left = 0.0
		_start_water_exit_animation()


func set_water_surface_y(surface_y: float) -> void:
	water_surface_y = surface_y
	has_water_surface_y = true


func clear_water_surface_y() -> void:
	has_water_surface_y = false


func die() -> void:
	if is_dead:
		return

	is_dead = true
	invincible = true
	is_hurt_animating = false
	hurt_animation_left = 0.0
	velocity = Vector2.ZERO
	_cancel_attack_state()
	_end_dash(false)
	_cancel_attack_charge()
	_set_all_attack_areas_enabled(false)
	animated_sprite.visible = false
	death_effect.visible = false
	_start_camera_shake(0.4, 10.0)
	died.emit()

	await get_tree().create_timer(respawn_delay).timeout
	_respawn()


func _apply_hurt_knockback(from_position: Vector2) -> void:
	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = -float(facing_direction)

	knockback_velocity = Vector2(push_direction * knockback_force, knockback_up_velocity)
	velocity = knockback_velocity
	hurt_lock_left = hurt_control_lock_time


func _start_invincibility() -> void:
	invincible = true
	var tween := create_tween()
	var flash_count: int = maxi(1, int(round(invincible_time / 0.2)))
	for i in range(flash_count):
		tween.tween_property(animated_sprite, "modulate:a", 0.35, invincible_time / (flash_count * 2.0))
		tween.tween_property(animated_sprite, "modulate:a", 1.0, invincible_time / (flash_count * 2.0))
	tween.finished.connect(_finish_invincibility)


func _finish_invincibility() -> void:
	animated_sprite.modulate = Color.WHITE
	invincible = false


func _respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	is_underwater = false
	has_water_surface_y = false
	reset_camera_limits()
	reset_camera_profile()
	_snap_camera_to_player()
	GameState.refill_health_potions()
	current_health = float(max_health)
	current_stamina = max_stamina
	stamina_recovery_delay_left = 0.0
	_sync_runtime_status()
	jump_count = 0
	hurt_lock_left = 0.0
	is_hurt_animating = false
	hurt_animation_left = 0.0
	_cancel_attack_state()
	_end_dash(false)
	_cancel_attack_charge()
	is_dead = false
	animated_sprite.visible = true
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("wait")
	death_effect.visible = false
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)
	respawned.emit()
	_start_invincibility()
	
	_respawn_room_enemies()


func _sync_runtime_status() -> void:
	GameState.set_player_runtime_status(current_health, max_health, current_stamina, max_stamina)


func _try_use_health_potion() -> bool:
	if is_dead or GameState.input_locked or _has_visible_interaction_prompt():
		return false
	if current_health >= float(max_health):
		_show_game_toast(_t("TOAST_HEALTH_FULL"))
		return false
	if not GameState.use_health_potion():
		_show_game_toast(_t("TOAST_NO_POTION"))
		return false

	heal(health_potion_heal_amount)
	_show_game_toast(_t("TOAST_POTION_USED"))
	return true


func _has_visible_interaction_prompt() -> bool:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui == null or not ui.has_method("has_prompt"):
		return false
	return bool(ui.call("has_prompt"))


func _show_game_toast(text: String) -> void:
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("show_toast"):
		ui.call("show_toast", text, 1.2)


func _t(key: String) -> String:
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _play_game_music() -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player != null and music_player.has_method("play_game_music"):
		music_player.play_game_music()


func _respawn_room_enemies() -> void:
	var manager := get_tree().get_first_node_in_group("room_manager")
	if manager != null and manager.has_method("respawn_enemies"):
		manager.respawn_enemies()

func _get_respawn_position() -> Vector2:
	var point: Node = get_tree().get_first_node_in_group("respawn_point")
	if point is Node2D:
		return point.global_position
	return global_position


func _get_spawn_position() -> Vector2:
	var marker_name := GameState.consume_pending_spawn_marker()
	if marker_name != "":
		var marker := _find_spawn_marker(marker_name)
		if marker != null:
			return marker.global_position

	return GameState.get_respawn_position(_get_respawn_position())


func _find_spawn_marker(marker_name: String) -> Node2D:
	for marker in get_tree().get_nodes_in_group("spawn_marker"):
		if marker is Node2D and marker.name == marker_name:
			return marker
	return null


func set_camera_profile(offset: Vector2, zoom: Vector2, smoothing_speed: float = 8.0) -> void:
	camera_follow_position = offset
	camera_follow_zoom = zoom
	camera_follow_smoothing_speed = smoothing_speed
	_configure_follow_camera()


func reset_camera_profile() -> void:
	camera_follow_position = default_camera_position
	camera_follow_zoom = default_camera_zoom
	camera_follow_smoothing_speed = default_camera_smoothing_speed
	_configure_follow_camera()


func reset_camera_after_water_exit() -> void:
	reset_camera_limits()
	camera_follow_position = default_camera_position
	camera_follow_zoom = default_camera_zoom
	camera_follow_smoothing_speed = water_exit_camera_smoothing_speed
	_configure_follow_camera()
	water_exit_camera_blend_left = water_exit_camera_blend_time


func reset_camera_limits() -> void:
	manual_camera_limits_enabled = false
	manual_camera_limit_left = -CAMERA_UNBOUNDED_LIMIT
	manual_camera_limit_top = -CAMERA_UNBOUNDED_LIMIT
	manual_camera_limit_right = CAMERA_UNBOUNDED_LIMIT
	manual_camera_limit_bottom = CAMERA_UNBOUNDED_LIMIT
	_configure_follow_camera()


func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	manual_camera_limits_enabled = true
	manual_camera_limit_left = left
	manual_camera_limit_top = top
	manual_camera_limit_right = right
	manual_camera_limit_bottom = bottom
	_configure_follow_camera()


func _configure_follow_camera() -> void:
	camera_base_offset = default_camera_offset
	camera.offset = camera_base_offset
	camera.position = camera_follow_position
	camera.zoom = camera_follow_zoom
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_follow_smoothing_speed
	_clear_camera_limits()
	_apply_scene_camera_limits()


func _clear_camera_limits() -> void:
	camera.limit_left = -CAMERA_UNBOUNDED_LIMIT
	camera.limit_top = -CAMERA_UNBOUNDED_LIMIT
	camera.limit_right = CAMERA_UNBOUNDED_LIMIT
	camera.limit_bottom = CAMERA_UNBOUNDED_LIMIT


func _apply_scene_camera_limits() -> void:
	if manual_camera_limits_enabled:
		camera.limit_left = manual_camera_limit_left
		camera.limit_top = manual_camera_limit_top
		camera.limit_right = manual_camera_limit_right
		camera.limit_bottom = manual_camera_limit_bottom

	if not use_map_wall_camera_limits:
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	var map_left := scene.find_child("map_left", true, false)
	if map_left is Node2D:
		camera.limit_left = maxi(camera.limit_left, floori(_get_node_world_rect(map_left).position.x))

	var map_right := scene.find_child("map_right", true, false)
	if map_right is Node2D:
		camera.limit_right = mini(camera.limit_right, ceili(_get_node_world_rect(map_right).end.x))

	var map_floor := scene.find_child("map_floor", true, false)
	if map_floor is Node2D:
		camera.limit_bottom = mini(camera.limit_bottom, ceili(_get_node_world_rect(map_floor).end.y))


func _snap_camera_to_player() -> void:
	if camera == null:
		return
	camera.reset_smoothing()
	camera.force_update_scroll()


func _get_node_world_rect(node: Node2D) -> Rect2:
	var shape_node := node.find_child("CollisionShape2D", true, false)
	if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		var shape_size: Vector2 = rect_shape.size * shape_node.global_scale.abs()
		return Rect2(shape_node.global_position - shape_size * 0.5, shape_size)

	return Rect2(node.global_position, Vector2.ZERO)


func _play_hit_effect(effect_position: Vector2) -> void:
	hit_effect.global_position = effect_position
	hit_effect.visible = true
	hit_effect.rotation = randf_range(-0.25, 0.25)
	hit_effect.play("hit")


func _play_attack_effect(attack_type: StringName) -> void:
	attack_effect.visible = true
	attack_effect.flip_h = false
	attack_effect.flip_v = false
	attack_effect.rotation = 0.0
	attack_effect.scale = attack_effect_base_scale
	attack_effect.modulate = Color.WHITE

	match attack_type:
		&"up":
			attack_effect.position = Vector2(0.0, -56.0)
			attack_effect.rotation = -PI / 2.0
		&"down":
			attack_effect.position = Vector2(0.0, 70.0)
			attack_effect.rotation = PI / 2.0
		&"charge":
			attack_effect.position = Vector2(76.0 * facing_direction, 0.0)
			attack_effect.scale = attack_effect_base_scale * 1.55
			attack_effect.modulate = Color(1.0, 0.72, 0.28, 1.0)
			attack_effect.flip_h = facing_direction < 0
		_:
			attack_effect.position = Vector2(52.0 * facing_direction, 0.0)
			attack_effect.flip_h = facing_direction < 0

	attack_effect.play("slash")


func _play_player_attack_animation(attack_type: StringName) -> void:
	if attack_type == &"up" and animated_sprite.sprite_frames.has_animation(&"attack_up"):
		animated_sprite.play(&"attack_up")
	else:
		animated_sprite.play(&"attack")


func _play_hurt_animation() -> void:
	if animated_sprite.sprite_frames.has_animation(&"damage"):
		is_hurt_animating = true
		hurt_animation_left = hurt_animation_time
		animated_sprite.play(&"damage")


func _update_hurt_animation_state(delta: float) -> void:
	if not is_hurt_animating:
		return

	hurt_animation_left -= delta
	if hurt_animation_left > 0.0 and animated_sprite.animation == &"damage":
		return

	is_hurt_animating = false
	hurt_animation_left = 0.0
	_update_animation()


func _cancel_attack_state() -> void:
	is_attacking = false
	attack_time_left = 0.0
	hit_targets.clear()
	_cancel_far_attack_hold()
	_set_all_attack_areas_enabled(false)
	attack_effect.visible = false
	charge_effect.visible = false


func _begin_attack_charge() -> void:
	if is_attacking or is_dashing:
		return

	is_charging_attack = true
	attack_charge_time = 0.0
	charge_ready = false
	_hide_charge_effect()


func _cancel_attack_charge() -> void:
	if not is_charging_attack and not charge_ready:
		return

	is_charging_attack = false
	attack_charge_time = 0.0
	charge_ready = false
	_hide_charge_effect()


func _show_charge_ready_effect() -> void:
	_update_charge_ready_effect()
	charge_effect.visible = true
	charge_effect.play("slash")


func _update_charge_ready_effect() -> void:
	charge_effect.position = Vector2(42.0 * facing_direction, -4.0)
	charge_effect.flip_h = facing_direction < 0
	charge_effect.rotation = 0.0
	charge_effect.scale = charge_effect_base_scale
	charge_effect.modulate = Color(1.0, 0.78, 0.34, 0.88)


func _hide_charge_effect() -> void:
	charge_effect.stop()
	charge_effect.visible = false
	charge_effect.modulate = Color.WHITE
	charge_effect.scale = charge_effect_base_scale


func _play_audio(audio: AudioStreamPlayer2D) -> void:
	if audio != null and audio.stream != null:
		audio.play()


func _setup_player_light() -> void:
	if not enable_player_light:
		return

	var scene: Node = get_tree().current_scene
	var demo_atmosphere := scene.get_node_or_null("Atmosphere/DemoCanvasModulate") if scene != null else null
	if scene != null and demo_atmosphere == null and scene.get_node_or_null("SceneDarkness") == null:
		var darkness: CanvasModulate = CanvasModulate.new()
		darkness.name = "SceneDarkness"
		darkness.color = scene_darkness
		scene.add_child.call_deferred(darkness)

	if get_node_or_null("PlayerLight") != null:
		return

	var light_texture: ImageTexture = _build_radial_light_texture(256)
	var light: Sprite2D = Sprite2D.new()
	var light_material: ShaderMaterial = ShaderMaterial.new()

	light_material.shader = CUSTOM_2D_LIGHT_SHADER
	light_material.set_shader_parameter("light_texture", light_texture)
	light_material.set_shader_parameter(
		"light_color",
		Vector3(player_light_color.r * 255.0, player_light_color.g * 255.0, player_light_color.b * 255.0)
	)
	light_material.set_shader_parameter("brightness", clampf(player_light_energy, 0.0, 1.0))
	light_material.set_shader_parameter("attenuation_strength", 0.35)
	light_material.set_shader_parameter("intensity", 1.0)
	light_material.set_shader_parameter("max_brightness", 1.0)

	light.name = "PlayerLight"
	light.texture = light_texture
	light.material = light_material
	light.scale = Vector2.ONE * (player_light_radius / 128.0)
	light.show_behind_parent = true
	light.z_index = -10
	add_child(light)


func _build_radial_light_texture(size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size, size) * 0.5
	var radius: float = float(size) * 0.5

	for y in range(size):
		for x in range(size):
			var distance: float = Vector2(x, y).distance_to(center) / radius
			var alpha: float = pow(clampf(1.0 - distance, 0.0, 1.0), 2.2)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	return ImageTexture.create_from_image(image)


func _start_camera_shake(duration: float, strength: float) -> void:
	shake_time_left = maxf(shake_time_left, duration)
	shake_strength = maxf(shake_strength, strength)


func _update_camera_shake(delta: float) -> void:
	if shake_time_left <= 0.0:
		camera.offset = camera_base_offset
		shake_strength = 0.0
		return

	shake_time_left -= delta
	var amount := shake_strength * (shake_time_left / maxf(shake_time_left + delta, 0.001))
	camera.offset = camera_base_offset + Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _update_motion_animation_timers(delta: float) -> void:
	if water_exit_animation_left > 0.0:
		water_exit_animation_left = maxf(water_exit_animation_left - delta, 0.0)
	if double_jump_animation_left > 0.0:
		double_jump_animation_left = maxf(double_jump_animation_left - delta, 0.0)
	if water_exit_camera_blend_left > 0.0:
		water_exit_camera_blend_left = maxf(water_exit_camera_blend_left - delta, 0.0)
		if is_zero_approx(water_exit_camera_blend_left):
			reset_camera_profile()


func _start_water_exit_animation() -> void:
	water_exit_animation_left = water_exit_animation_time
	double_jump_animation_left = 0.0
	_spawn_water_exit_splash()
	if animated_sprite.sprite_frames.has_animation(&"water_exit"):
		animated_sprite.play(&"water_exit")


func _start_double_jump_animation() -> void:
	double_jump_animation_left = double_jump_animation_time
	if animated_sprite.sprite_frames.has_animation(&"double_jump"):
		animated_sprite.play(&"double_jump")


func _spawn_water_exit_splash() -> void:
	_spawn_motion_particles(
		WATER_EXIT_PARTICLE_TEXTURE,
		global_position + Vector2(0.0, -10.0),
		Color(0.58, 0.92, 1.0, 0.78),
		8,
		Vector2(62.0, 22.0),
		Vector2(18.0, -72.0),
		0.42,
		Vector2(0.18, 0.18),
		Vector2(0.48, 0.48)
	)


func _spawn_double_jump_burst() -> void:
	_spawn_motion_particles(
		AIR_JUMP_PARTICLE_TEXTURE,
		global_position + Vector2(0.0, 10.0),
		Color(0.82, 0.96, 1.0, 0.74),
		6,
		Vector2(44.0, 18.0),
		Vector2(0.0, 48.0),
		0.34,
		Vector2(0.12, 0.12),
		Vector2(0.34, 0.34)
	)


func _play_dash_animation(direction_vector: Vector2) -> void:
	var original_scale := animated_sprite.scale
	var stretch := Vector2(original_scale.x * 1.18, original_scale.y * 0.82)
	if absf(direction_vector.y) > absf(direction_vector.x):
		stretch = Vector2(original_scale.x * 0.88, original_scale.y * 1.16)
	var tween := create_tween()
	tween.tween_property(animated_sprite, "scale", stretch, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(animated_sprite, "scale", original_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _update_dash_trail(_delta: float, _direction_vector: Vector2) -> void:
	pass


func _spawn_dash_trail(direction_vector: Vector2, count: int) -> void:
	if direction_vector == Vector2.ZERO:
		direction_vector = Vector2(float(facing_direction), 0.0)
	var opposite := -direction_vector.normalized()
	var color := Color(0.72, 0.95, 1.0, 0.66) if not is_underwater else Color(0.36, 0.9, 1.0, 0.74)
	_spawn_motion_particles(
		AIR_JUMP_PARTICLE_TEXTURE,
		global_position + opposite * 28.0 + Vector2(0.0, -2.0),
		color,
		count,
		Vector2(18.0, 20.0),
		opposite * 78.0 + Vector2(0.0, 8.0),
		0.24,
		Vector2(0.1, 0.1),
		Vector2(0.34, 0.34)
	)


func _spawn_motion_particles(
	texture: Texture2D,
	origin: Vector2,
	color: Color,
	count: int,
	spread: Vector2,
	drift: Vector2,
	duration: float,
	start_scale: Vector2,
	end_scale: Vector2
) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.is_node_ready():
		return
	if Engine.get_process_frames() < 3:
		return

	for index in range(count):
		var particle := Sprite2D.new()
		particle.name = "MotionParticle"
		particle.texture = texture
		particle.centered = true
		particle.modulate = color
		particle.scale = start_scale * randf_range(0.72, 1.2)
		particle.global_position = origin + Vector2(
			randf_range(-spread.x, spread.x),
			randf_range(-spread.y, spread.y)
		)
		particle.z_index = z_index + 4

		var side := randf_range(-1.0, 1.0)
		var target_position := particle.global_position + Vector2(drift.x * side, drift.y) + Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 10.0))
		var target_scale := end_scale * randf_range(0.78, 1.15)
		call_deferred("_attach_motion_particle", parent, particle, target_position, duration, target_scale)


func _attach_motion_particle(parent: Node, particle: Sprite2D, target_position: Vector2, duration: float, target_scale: Vector2) -> void:
	if parent == null or particle == null or not is_instance_valid(parent) or not is_instance_valid(particle):
		return
	parent.add_child(particle)
	_animate_motion_particle(particle, target_position, duration, target_scale)


func _animate_motion_particle(particle: Sprite2D, target_position: Vector2, duration: float, target_scale: Vector2) -> void:
	if particle == null or not is_instance_valid(particle) or not particle.is_inside_tree():
		return
	var tween := particle.create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(particle, "queue_free"))


func _update_animation() -> void:
	if is_hurt_animating:
		return

	if is_attacking and animated_sprite.animation != &"damage":
		return

	if water_exit_animation_left > 0.0 and animated_sprite.sprite_frames.has_animation(&"water_exit"):
		if animated_sprite.animation != &"water_exit":
			animated_sprite.play(&"water_exit")
		return

	if double_jump_animation_left > 0.0 and animated_sprite.sprite_frames.has_animation(&"double_jump"):
		if animated_sprite.animation != &"double_jump":
			animated_sprite.play(&"double_jump")
		return

	if is_dashing:
		var dash_animation := &"walk"
		if is_underwater and animated_sprite.sprite_frames.has_animation(&"swimming"):
			dash_animation = &"swimming"
		if animated_sprite.animation != dash_animation:
			animated_sprite.play(dash_animation)
		return

	if is_underwater:
		var underwater_animation := &"swimming"
		if _is_underwater_wall_swimming() and animated_sprite.sprite_frames.has_animation(&"underwater_slide"):
			underwater_animation = &"underwater_slide"
		if not animated_sprite.sprite_frames.has_animation(underwater_animation):
			underwater_animation = &"walk"
		if animated_sprite.animation != underwater_animation:
			animated_sprite.play(underwater_animation)
		return

	if not is_on_floor():
		var air_animation := &"jump"
		if _can_wall_slide() and animated_sprite.sprite_frames.has_animation(&"wall_slide"):
			air_animation = &"wall_slide"
		if animated_sprite.animation != air_animation:
			animated_sprite.play(air_animation)
	elif absf(velocity.x) > 1.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "wait":
			animated_sprite.play("wait")


func _on_animated_sprite_animation_finished() -> void:
	if animated_sprite.animation == &"damage":
		is_hurt_animating = false
		hurt_animation_left = 0.0
		_update_animation()
		return

	if animated_sprite.animation != "attack" and animated_sprite.animation != "attack_up":
		return

	is_attacking = false
	_update_animation()


func _on_attack_effect_animation_finished() -> void:
	attack_effect.visible = false
	attack_effect.modulate = Color.WHITE
	attack_effect.scale = attack_effect_base_scale


func _on_charge_effect_animation_finished() -> void:
	if is_charging_attack and charge_ready:
		charge_effect.play("slash")
		return

	charge_effect.visible = false


func _on_hit_effect_animation_finished() -> void:
	hit_effect.visible = false


func _on_death_effect_animation_finished() -> void:
	if not is_dead:
		death_effect.visible = false
