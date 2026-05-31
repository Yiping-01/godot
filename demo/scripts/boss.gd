extends CharacterBody2D

const DEMO_COMBAT_JUICE := preload("res://demo/scripts/demo_combat_juice.gd")
const DASH_FRAME_PATHS: Array[String] = [
	"res://demo/assets/boss/boss_go/bossgo_1.png",
	"res://demo/assets/boss/boss_go/bossgo_2.png",
	"res://demo/assets/boss/boss_go/bossgo_3.png",
	"res://demo/assets/boss/boss_go/bossgo_4.png",
]

const JUMP_FRAME_PATHS: Array[String] = [
	"res://demo/assets/boss/bossjump/boss01_v1_jump_01.png",
	"res://demo/assets/boss/bossjump/boss01_v1_jump_02.png",
	"res://demo/assets/boss/bossjump/boss01_v1_jump_03.png",
	"res://demo/assets/boss/bossjump/boss01_v1_jump_04.png",
]

const THROW_FRAME_PATHS: Array[String] = [
	"res://demo/assets/boss/boss_throw/boss_throw1.png",
	"res://demo/assets/boss/boss_throw/boss_throw2.png",
	"res://demo/assets/boss/boss_throw/boss_throw3.png",
	"res://demo/assets/boss/boss_throw/boss_throw4.png",
]
const PLAYER_BODY_COLLISION_LAYER_NUMBER := 2
const SOLID_BODY_COLLISION_LAYER_NUMBER := 1

@export var max_health: int = 10
@export var monster_id: String = "Boss"
@export var gravity: float = 1600.0
@export var dash_speed: float = 760.0
@export var dash_time: float = 0.42
@export var dash_animation_frame_time: float = 0.08
@export var dash_animation_flipped: bool = true
@export var windup_time: float = 0.55
@export var recover_time: float = 0.8
@export var attack_switch_pause_time: float = 0.5
@export var idle_decision_time: float = 0.35
@export var min_attack_cycles_before_rest: int = 2
@export var max_attack_cycles_before_rest: int = 3
@export var rest_time: float = 1.15
@export var attack_range: float = 720.0
@export var close_attack_range: float = 360.0
@export var vertical_tolerance: float = 180.0
@export var contact_damage: int = 1
@export var body_contact_damage_enabled: bool = true
@export var body_contact_damage_interval: float = 0.35
@export var body_contact_damage_margin: float = 24.0
@export var player_body_collision_ignore_time: float = 0.35
@export var dash_telegraph_length: float = 720.0
@export var dash_telegraph_y_offset: float = 95.0
@export var dash_hitbox_size := Vector2(132.0, 46.0)
@export var dash_hitbox_offset := Vector2(90.0, 42.0)
@export var hurt_knockback: float = 240.0
@export var hit_stun_time: float = 0.18
@export var quake_windup_time: float = 0.55
@export var quake_jump_velocity: float = -620.0
@export var quake_rise_gravity: float = 650.0
@export var quake_fall_gravity: float = 1900.0
@export var jump_rise_animation_frame_time: float = 0.3
@export var jump_fall_animation_frame_time: float = 0.08
@export var quake_damage: int = 1
@export var quake_recover_time: float = 0.7
@export var quake_camera_shake_duration: float = 0.7
@export var quake_camera_shake_strength: float = 7.0
@export var quake_wave_duration: float = 0.45
@export var quake_wave_width: float = 520.0
@export var quake_wave_height: float = 34.0
@export var quake_wave_line_width: float = 8.0
@export var quake_wave_y_offset: float = 70.0
@export var quake_floor_wave_width: float = 1800.0
@export var quake_floor_wave_height: float = 24.0
@export var quake_damage_width: float = 1180.0
@export var quake_damage_hitbox_height: float = 124.0
@export var quake_damage_hitbox_y_offset: float = 70.0
@export var min_quake_attacks_before_forced_other: int = 1
@export var max_quake_attacks_before_forced_other: int = 2
@export var min_ranged_attacks_before_forced_close: int = 1
@export var max_ranged_attacks_before_forced_close: int = 2
@export var ink_attack_windup_time: float = 0.45
@export var ink_attack_recover_time: float = 0.75
@export var throw_animation_frame_time: float = 0.09
@export var throw_animation_scale_multiplier: float = 0.81
@export var ink_projectile_speed: float = 380.0
@export var ink_projectile_min_count: int = 5
@export var ink_projectile_max_count: int = 6
@export var ink_projectile_min_batch: int = 1
@export var ink_projectile_max_batch: int = 2
@export var ink_projectile_min_height: float = -58.0
@export var ink_projectile_max_height: float = 52.0
@export var ink_projectile_min_interval: float = 0.46
@export var ink_projectile_max_interval: float = 0.68
@export var ink_projectile_min_speed_multiplier: float = 0.75
@export var ink_projectile_max_speed_multiplier: float = 1.35
@export var ink_projectile_min_wave_amplitude: float = 18.0
@export var ink_projectile_max_wave_amplitude: float = 34.0
@export var ink_projectile_min_wave_frequency: float = 3.8
@export var ink_projectile_max_wave_frequency: float = 5.4
@export var ink_projectile_scene: PackedScene = preload("res://demo/scenes/ink_projectile.tscn")
@export var intro_effect_enabled: bool = true
@export var start_inactive: bool = false
@export var intro_effect_duration: float = 2.8
@export var intro_ring_start_interval: float = 0.32
@export var intro_ring_end_interval: float = 0.07
@export var intro_ring_radius: float = 72.0
@export var intro_ring_max_scale: float = 14.0
@export var intro_ring_width: float = 10.0
@export var intro_spike_count: int = 18
@export var intro_spike_inner_radius: float = 42.0
@export var intro_spike_outer_radius: float = 118.0
@export var intro_spike_angle_width: float = 0.08
@export var intro_center_glow_radius: float = 96.0
@export var intro_min_shake_strength: float = 2.0
@export var intro_max_shake_strength: float = 13.0
@export var intro_sfx: AudioStream = preload("res://demo/assets/audio/scores/boss1.wav")
@export var intro_sfx_volume_db: float = 6.0
@export var ink_sfx: AudioStream = preload("res://demo/assets/audio/scores/boss_attack1.wav")
@export var ink_sfx_volume_db: float = 0.0
@export var dash_end_impact_shake := 7.5
@export var dash_combo_phase_one_min := 1
@export var dash_combo_phase_one_max := 2
@export var dash_chain_pause_time := 0.22
@export var anti_pogo_hit_window: float = 1.15
@export var anti_pogo_hits_before_counter: int = 2
@export var anti_pogo_counter_cooldown: float = 1.0
@export var anti_pogo_windup_time: float = 0.16
@export var anti_pogo_launch_velocity: float = -540.0
@export var anti_pogo_damage_width: float = 440.0
@export var anti_pogo_damage_height: float = 168.0
@export var anti_pogo_damage_y_offset: float = -92.0
@export var anti_pogo_damage: int = 1
@export var anti_pogo_recover_time: float = 0.5
@export var coin_drop_amount: int = 12
@export var coin_scene: PackedScene = preload("res://demo/scenes/coin_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D
@onready var quake_damage_area: Area2D = get_node_or_null("QuakeDamageArea")
@onready var quake_damage_shape: CollisionShape2D = get_node_or_null("QuakeDamageArea/CollisionShape2D")
@onready var windup_particles: CPUParticles2D = get_node_or_null("WindupParticles")
@onready var rest_breath_particles: CPUParticles2D = get_node_or_null("RestBreathParticles")
@onready var quake_impact_particles: CPUParticles2D = get_node_or_null("QuakeImpactParticles")

var health := 0
var state := &"idle"
var state_timer := 0.0
var idle_decision_left := 0.0
var next_attack_after_pause := &"any"
var direction := -1
var hit_stun_left := 0.0
var ink_projectiles_left := 0
var ink_projectile_index := 0
var ink_next_shot_time := 0.0
var ranged_attack_count := 0
var ranged_attacks_before_forced_close := 0
var quake_attack_count := 0
var quake_attacks_before_forced_other := 0
var finished_attack_cycles_since_rest := 0
var attack_cycles_before_rest := 0
var quake_has_left_floor := false
var default_texture: Texture2D
var default_sprite_scale := Vector2.ONE
var default_sprite_modulate := Color.WHITE
var dash_frames: Array[Texture2D] = []
var jump_frames: Array[Texture2D] = []
var throw_frames: Array[Texture2D] = []
var dash_frame_index := 0
var dash_frame_time_left := 0.0
var jump_rise_frame_index := 0
var jump_fall_frame_index := 0
var jump_frame_time_left := 0.0
var throw_frame_index := 0
var throw_frame_time_left := 0.0
var throw_animation_active := false
var intro_time_left := 0.0
var intro_elapsed := 0.0
var intro_next_ring_time := 0.0
var intro_audio: AudioStreamPlayer
var body_contact_area: Area2D
var body_contact_shape: CollisionShape2D
var body_contact_targets: Array[Area2D] = []
var body_contact_damage_cooldown := 0.0
var last_solid_floor_y := 100000000.0
var normal_collision_mask := 0
var player_body_collision_ignore_left := 0.0
var target: Node2D
var is_defeated := false
var unlock_achievement_on_death := false
var telegraph_node: Node2D
var telegraph_line: Line2D
var telegraph_tween: Tween
var dash_combo_left := 0
var head_hit_count := 0
var head_hit_timer := 0.0
var anti_pogo_cooldown_left := 0.0
var dash_afterimage_left := 0.0
var quake_warning: Node2D


func _ready() -> void:
	health = max_health
	set_collision_layer_value(SOLID_BODY_COLLISION_LAYER_NUMBER, true)
	normal_collision_mask = collision_mask
	set_collision_mask_value(PLAYER_BODY_COLLISION_LAYER_NUMBER, false)
	normal_collision_mask = collision_mask
	default_texture = sprite.texture
	default_sprite_scale = sprite.scale
	default_sprite_modulate = sprite.modulate
	_configure_dash_hitbox()
	_load_dash_frames()
	_load_jump_frames()
	_load_throw_frames()
	ranged_attacks_before_forced_close = _roll_ranged_attacks_before_forced_close()
	quake_attacks_before_forced_other = _roll_quake_attacks_before_forced_other()
	attack_cycles_before_rest = _roll_attack_cycles_before_rest()
	add_to_group("enemy")
	damage_area.area_entered.connect(_on_damage_area_entered)
	_setup_body_contact_area()
	_setup_quake_damage_area()
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_windup_effect(false)
	_set_rest_effect(false)
	_sync_facing()
	if intro_effect_enabled:
		_start_intro_effect()
	if start_inactive:
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	target = _find_player()
	_update_anti_pogo_timers(delta)
	_update_player_body_collision_ignore(delta)

	if not is_on_floor():
		velocity.y += _get_current_gravity() * delta

	if intro_time_left > 0.0:
		_update_intro_effect(delta)
		velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	elif hit_stun_left > 0.0:
		hit_stun_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback * delta * 3.0)
	else:
		match state:
			&"windup":
				_update_windup(delta)
			&"dash":
				_update_dash(delta)
			&"recover":
				_update_recover(delta)
			&"attack_pause":
				_update_attack_pause(delta)
			&"ink_windup":
				_update_ink_windup(delta)
			&"ink_fire":
				_update_ink_fire(delta)
			&"ink_recover":
				_update_ink_recover(delta)
			&"quake_windup":
				_update_quake_windup(delta)
			&"quake_jump":
				_update_quake_jump(delta)
			&"quake_recover":
				_update_quake_recover(delta)
			&"anti_pogo_windup":
				_update_anti_pogo_windup(delta)
			&"anti_pogo_launch":
				_update_anti_pogo_launch(delta)
			&"anti_pogo_recover":
				_update_anti_pogo_recover(delta)
			&"rest":
				_update_rest(delta)
			_:
				_update_idle(delta)

	var was_falling_jump := _is_falling_jump_body_contact()
	_update_boss_animation(delta)
	move_and_slide()
	_damage_jump_body_collisions(was_falling_jump)
	_resolve_player_floor_collisions()
	_update_last_solid_floor_y()
	_update_body_contact_damage(delta)


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_defeated:
		return

	health -= amount
	var push_direction := signf(global_position.x - from_position.x)
	if is_zero_approx(push_direction):
		push_direction = 1.0

	hit_stun_left = hit_stun_time
	velocity.x = push_direction * hurt_knockback
	_flash()

	if health <= 0:
		_begin_death_sequence()
		return

	if _is_head_pogo_hit(from_position):
		_record_head_pogo_hit()

	DEMO_COMBAT_JUICE.play_hit_pause(self, 0.055, 0.08)


func can_receive_player_attack(_attack_type: StringName = &"side", _attacker_position: Vector2 = Vector2.ZERO, _attacker_velocity: Vector2 = Vector2.ZERO) -> bool:
	if state == &"quake_jump" or state == &"anti_pogo_launch":
		return velocity.y >= 0.0
	return true


func _begin_death_sequence() -> void:
	if is_defeated:
		return

	is_defeated = true
	if unlock_achievement_on_death:
		_unlock_kill_achievement()
	velocity = Vector2.ZERO
	_clear_attack_telegraph()
	_set_windup_effect(false)
	_set_rest_effect(false)
	collision_layer = 0
	collision_mask = 0
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if damage_shape != null:
		damage_shape.set_deferred("disabled", true)
	if body_contact_area != null:
		body_contact_area.set_deferred("monitoring", false)
		body_contact_area.set_deferred("monitorable", false)
	body_contact_targets.clear()
	DEMO_COMBAT_JUICE.shake_camera(self, 1.15, 18.0)
	DEMO_COMBAT_JUICE.spawn_boss_death_sequence(self, global_position, 1.08)
	call_deferred("_drop_bottles")
	_notify_boss_defeat_started()
	_play_demo_defeat_sfx()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.76, 0.22, 0.25), 0.42)
	tween.tween_property(sprite, "scale", sprite.scale * 1.08, 0.42)
	tween.chain().tween_interval(0.55)
	tween.chain().tween_property(sprite, "modulate:a", 0.0, 0.36)
	tween.tween_callback(Callable(self, "queue_free"))


func _unlock_kill_achievement() -> void:
	var achievement_manager := get_node_or_null("/root/AchievementManager")
	if achievement_manager != null and achievement_manager.has_method("unlock_kill_achievement"):
		achievement_manager.call("unlock_kill_achievement", monster_id)


func _notify_boss_defeat_started() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_on_demo_boss_defeated_started"):
		scene.call("_on_demo_boss_defeated_started", self)
		return

	var parent := get_parent()
	if parent != null and parent.has_method("_on_demo_boss_defeated_started"):
		parent.call("_on_demo_boss_defeated_started", self)


func _play_demo_defeat_sfx() -> void:
	if not DEMO_COMBAT_JUICE.is_enabled(self):
		return

	var stream := load("res://demo/assets/hollow_import/audio/boss_explode.wav")
	if stream == null:
		return

	var sfx := AudioStreamPlayer2D.new()
	sfx.name = "DemoBossDefeatSfx"
	sfx.stream = stream
	sfx.volume_db = -2.0
	sfx.global_position = global_position
	get_parent().add_child(sfx)
	sfx.finished.connect(Callable(sfx, "queue_free"))
	sfx.play()


func _update_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * 0.08)
	if not _can_dash_attack():
		idle_decision_left = idle_decision_time
		return

	_face_target()
	idle_decision_left -= _delta
	if idle_decision_left > 0.0:
		_apply_ready_pose(1.0 - idle_decision_left / maxf(idle_decision_time, 0.001))
		return

	_reset_sprite_pose()
	idle_decision_left = idle_decision_time
	_begin_random_attack()


func _update_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	_update_dash_telegraph()
	_apply_windup_pose(1.0 - state_timer / maxf(windup_time, 0.001), Color(1.0, 0.35, 0.22, 1.0))
	state_timer -= delta
	if state_timer > 0.0:
		return

	_clear_attack_telegraph()
	_set_windup_effect(false)
	_reset_sprite_pose()
	state = &"dash"
	state_timer = dash_time
	dash_afterimage_left = 0.0
	velocity.x = direction * dash_speed
	_set_damage_area_enabled(true)
	_start_dash_animation()


func _update_dash(delta: float) -> void:
	state_timer -= delta
	velocity.x = direction * dash_speed
	dash_afterimage_left -= delta
	if dash_afterimage_left <= 0.0:
		dash_afterimage_left = 0.05
		_spawn_dash_afterimage(0.22)
	if state_timer > 0.0:
		return

	_set_damage_area_enabled(false)
	_play_dash_end_impact()
	_stop_dash_animation()
	state = &"recover"
	state_timer = recover_time


func _update_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.0)
	state_timer -= delta
	if state_timer <= 0.0:
		if dash_combo_left > 0 and target != null:
			dash_combo_left -= 1
			_begin_dash_chain_pause()
			return
		if target != null:
			_begin_attack_pause(&"special_after_dash")
			return
		state = &"idle"


func _update_attack_pause(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.0)
	_face_target()
	state_timer -= delta
	if state_timer > 0.0:
		return

	if next_attack_after_pause == &"special_after_dash":
		_begin_random_special_after_dash()
	else:
		_begin_random_attack()


func _update_ink_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	_apply_windup_pose(1.0 - state_timer / maxf(ink_attack_windup_time, 0.001), Color(0.35, 0.78, 1.0, 1.0))
	state_timer -= delta
	if state_timer > 0.0:
		return

	_clear_attack_telegraph()
	_set_windup_effect(false)
	_reset_sprite_pose()
	_begin_ink_fire()


func _update_ink_fire(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	ink_next_shot_time -= delta
	if ink_next_shot_time > 0.0:
		return

	var batch_count := randi_range(ink_projectile_min_batch, ink_projectile_max_batch)
	batch_count = mini(batch_count, ink_projectiles_left)
	for _shot in range(batch_count):
		_start_throw_animation()
		_shoot_one_ink()
		ink_projectile_index += 1
		ink_projectiles_left -= 1

	if ink_projectiles_left > 0:
		ink_next_shot_time = randf_range(ink_projectile_min_interval, ink_projectile_max_interval)
		return

	state = &"ink_recover"
	state_timer = ink_attack_recover_time


func _update_ink_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_finish_attack_cycle()


func _update_quake_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	_face_target()
	_apply_windup_pose(1.0 - state_timer / maxf(quake_windup_time, 0.001), Color(1.0, 0.92, 0.42, 1.0))
	state_timer -= delta
	if state_timer > 0.0:
		return

	_reset_sprite_pose()
	_set_windup_effect(false)
	_launch_quake_jump()


func _update_quake_jump(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	if not is_on_floor():
		quake_has_left_floor = true
	if quake_has_left_floor and is_on_floor() and velocity.y >= 0.0:
		_trigger_quake()
		state = &"quake_recover"
		state_timer = quake_recover_time


func _update_quake_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta)
	state_timer -= delta
	if state_timer <= 0.0:
		_finish_attack_cycle()


func _update_rest(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.4)
	_face_target()
	_apply_rest_pose()
	_set_rest_effect(true)
	state_timer -= delta
	if state_timer > 0.0:
		return

	_set_rest_effect(false)
	_reset_sprite_pose()
	state = &"idle"


func _update_anti_pogo_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.8)
	_face_target()
	_apply_windup_pose(1.0 - state_timer / maxf(anti_pogo_windup_time, 0.001), Color(1.0, 0.88, 0.38, 1.0))
	state_timer -= delta
	if state_timer > 0.0:
		return

	_launch_anti_pogo_counter()


func _update_anti_pogo_launch(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 1.7)
	state_timer -= delta
	if state_timer <= 0.0 and velocity.y >= 0.0:
		state = &"anti_pogo_recover"
		state_timer = anti_pogo_recover_time
		_set_quake_damage_area_enabled(false)


func _update_anti_pogo_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, dash_speed * delta * 2.5)
	state_timer -= delta
	if state_timer <= 0.0:
		_reset_sprite_pose()
		_finish_attack_cycle()


func _begin_attack_pause(next_attack: StringName = &"any") -> void:
	dash_combo_left = 0
	next_attack_after_pause = next_attack
	state = &"attack_pause"
	state_timer = attack_switch_pause_time
	velocity.x = 0.0
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_clear_attack_telegraph()
	_clear_quake_warning()
	_reset_sprite_pose()
	idle_decision_left = idle_decision_time
	_set_windup_effect(false)


func _finish_attack_cycle() -> void:
	finished_attack_cycles_since_rest += 1
	if finished_attack_cycles_since_rest >= attack_cycles_before_rest:
		_begin_rest()
		return
	_begin_attack_pause()


func _begin_rest() -> void:
	state = &"rest"
	state_timer = rest_time
	velocity.x = 0.0
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_clear_attack_telegraph()
	_clear_quake_warning()
	finished_attack_cycles_since_rest = 0
	attack_cycles_before_rest = _roll_attack_cycles_before_rest()
	_apply_rest_pose()
	idle_decision_left = idle_decision_time
	_set_windup_effect(false)
	_set_rest_effect(true)


func _begin_dash_attack() -> void:
	idle_decision_left = idle_decision_time
	dash_combo_left = _roll_dash_combo_count() - 1
	_reset_ranged_attack_count()
	_reset_quake_attack_count()
	_face_target()
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_windup_effect(true, Color(1.0, 0.5, 0.25, 0.86))
	state = &"windup"
	state_timer = windup_time


func _begin_dash_chain_pause() -> void:
	state = &"windup"
	state_timer = dash_chain_pause_time
	velocity.x = 0.0
	_face_target()
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_windup_effect(true, Color(1.0, 0.72, 0.32, 0.86))


func _begin_ink_attack() -> void:
	idle_decision_left = idle_decision_time
	_reset_quake_attack_count()
	ranged_attack_count += 1
	_face_target()
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_windup_effect(true, Color(0.42, 0.9, 1.0, 0.78))
	state = &"ink_windup"
	state_timer = ink_attack_windup_time


func _begin_ink_fire() -> void:
	state = &"ink_fire"
	ink_projectiles_left = randi_range(ink_projectile_min_count, ink_projectile_max_count)
	ink_projectile_index = 0
	ink_next_shot_time = 0.0


func _begin_quake_jump() -> void:
	idle_decision_left = idle_decision_time
	_reset_ranged_attack_count()
	quake_attack_count += 1
	_set_damage_area_enabled(false)
	_configure_quake_damage_area()
	_set_quake_damage_area_enabled(true)
	_set_windup_effect(true, Color(1.0, 0.92, 0.42, 0.84))
	_spawn_quake_warning()
	state = &"quake_windup"
	state_timer = quake_windup_time


func _launch_quake_jump() -> void:
	state = &"quake_jump"
	quake_has_left_floor = false
	_snap_to_last_solid_floor_before_jump()
	velocity.x = 0.0
	velocity.y = quake_jump_velocity
	_set_windup_effect(false)
	_start_jump_animation()


func _update_anti_pogo_timers(delta: float) -> void:
	if head_hit_timer > 0.0:
		head_hit_timer -= delta
		if head_hit_timer <= 0.0:
			head_hit_count = 0
	if anti_pogo_cooldown_left > 0.0:
		anti_pogo_cooldown_left -= delta


func _is_head_pogo_hit(from_position: Vector2) -> bool:
	if from_position == Vector2.ZERO:
		return false
	return from_position.y < global_position.y - 42.0


func _record_head_pogo_hit() -> void:
	if anti_pogo_cooldown_left > 0.0:
		return
	head_hit_count += 1
	head_hit_timer = anti_pogo_hit_window
	if head_hit_count < anti_pogo_hits_before_counter:
		return
	_begin_anti_pogo_counter()


func _begin_anti_pogo_counter() -> void:
	head_hit_count = 0
	head_hit_timer = 0.0
	anti_pogo_cooldown_left = anti_pogo_counter_cooldown
	dash_combo_left = 0
	_clear_attack_telegraph()
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_rest_effect(false)
	_set_windup_effect(true, Color(1.0, 0.86, 0.34, 0.9))
	state = &"anti_pogo_windup"
	state_timer = anti_pogo_windup_time
	velocity = Vector2.ZERO
	DEMO_COMBAT_JUICE.shake_camera(self, 0.16, 6.0)


func _launch_anti_pogo_counter() -> void:
	_set_windup_effect(false)
	_reset_sprite_pose()
	_snap_to_last_solid_floor_before_jump()
	_configure_anti_pogo_damage_area()
	_set_quake_damage_area_enabled(true)
	if quake_damage_area != null and quake_damage_shape != null:
		quake_damage_area.monitoring = true
		quake_damage_shape.disabled = false
	_damage_anti_pogo_area_overlaps()
	DEMO_COMBAT_JUICE.shake_camera(self, 0.22, 8.5)
	velocity.x = 0.0
	velocity.y = anti_pogo_launch_velocity
	state = &"anti_pogo_launch"
	state_timer = 0.18
	_start_jump_animation()


func _trigger_quake() -> void:
	_clear_attack_telegraph()
	_configure_quake_damage_area()
	_flash_quake_warning()
	_play_quake_impact_effect()
	if target != null and target.has_method("_start_camera_shake"):
		target.call("_start_camera_shake", quake_camera_shake_duration, quake_camera_shake_strength)
	_damage_quake_area_overlaps()
	await get_tree().create_timer(0.12).timeout
	_set_quake_damage_area_enabled(false)
	_clear_quake_warning()


func _is_target_on_floor() -> bool:
	if target is CharacterBody2D:
		return target.is_on_floor()
	return false


func _spawn_quake_wave() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var wave := Node2D.new()
	wave.name = "QuakeWave"
	wave.z_index = 180
	parent.add_child(wave)
	wave.global_position = global_position + Vector2(0.0, quake_wave_y_offset)

	var fill := Polygon2D.new()
	fill.name = "QuakeWaveFill"
	fill.color = Color(1.0, 1.0, 1.0, 0.08)
	fill.polygon = _build_ellipse_points(quake_wave_width * 0.5, quake_wave_height * 0.5, 72)
	wave.add_child(fill)

	var floor_flash := Polygon2D.new()
	floor_flash.name = "QuakeFloorFlash"
	floor_flash.color = Color(1.0, 1.0, 1.0, 0.22)
	floor_flash.polygon = _build_floor_wave_polygon(quake_floor_wave_width, quake_floor_wave_height)
	wave.add_child(floor_flash)

	var ring := Line2D.new()
	ring.name = "QuakeWaveRing"
	ring.closed = true
	ring.width = quake_wave_line_width
	ring.default_color = Color(1.0, 1.0, 1.0, 0.55)
	ring.points = _build_ellipse_points(quake_wave_width * 0.5, quake_wave_height * 0.5, 96)
	wave.add_child(ring)

	for index in range(3):
		var floor_line := Line2D.new()
		floor_line.name = "QuakeFloorLine"
		floor_line.width = maxf(2.0, quake_wave_line_width - float(index) * 2.0)
		floor_line.default_color = Color(1.0, 1.0, 1.0, 0.5 - float(index) * 0.12)
		var line_y := float(index - 1) * quake_floor_wave_height * 0.35
		floor_line.points = PackedVector2Array([
			Vector2(-quake_floor_wave_width * 0.5, line_y),
			Vector2(quake_floor_wave_width * 0.5, line_y),
		])
		wave.add_child(floor_line)

	wave.scale = Vector2(0.05, 0.18)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(wave, "scale", Vector2(1.0, 1.0), quake_wave_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave, "modulate:a", 0.0, quake_wave_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_queue_free_instance_id.bind(wave.get_instance_id()))


func _spawn_quake_warning() -> void:
	_clear_quake_warning()
	var parent := get_parent()
	if parent == null:
		return
	quake_warning = Node2D.new()
	quake_warning.name = "BossQuakeWarning"
	quake_warning.z_index = 265
	parent.add_child(quake_warning)
	quake_warning.global_position = global_position + Vector2(0.0, quake_wave_y_offset)

	var zone := Polygon2D.new()
	zone.name = "DamagePreview"
	zone.color = Color(1.0, 0.4, 0.16, 0.2)
	zone.polygon = PackedVector2Array([
		Vector2(-quake_damage_width * 0.5, -quake_damage_hitbox_height * 0.5),
		Vector2(quake_damage_width * 0.5, -quake_damage_hitbox_height * 0.5),
		Vector2(quake_damage_width * 0.5, quake_damage_hitbox_height * 0.5),
		Vector2(-quake_damage_width * 0.5, quake_damage_hitbox_height * 0.5),
	])
	quake_warning.add_child(zone)

	var left_line := Line2D.new()
	left_line.name = "DangerLine"
	left_line.width = 5.0
	left_line.default_color = Color(1.0, 0.74, 0.22, 0.78)
	left_line.add_point(Vector2(-quake_damage_width * 0.5, 0.0))
	left_line.add_point(Vector2(quake_damage_width * 0.5, 0.0))
	quake_warning.add_child(left_line)

	var tween := quake_warning.create_tween()
	tween.set_loops()
	tween.tween_property(quake_warning, "modulate:a", 0.35, 0.16)
	tween.tween_property(quake_warning, "modulate:a", 0.85, 0.16)


func _flash_quake_warning() -> void:
	if quake_warning == null or not is_instance_valid(quake_warning):
		return
	quake_warning.modulate = Color(1.0, 1.0, 1.0, 1.0)
	quake_warning.scale = Vector2(1.0, 1.22)


func _clear_quake_warning() -> void:
	if quake_warning != null and is_instance_valid(quake_warning):
		quake_warning.queue_free()
	quake_warning = null


func _drop_bottles() -> void:
	if coin_scene == null:
		GameState.add_currency(coin_drop_amount)
		return
	var parent := get_parent()
	if parent == null:
		return
	for i in range(coin_drop_amount):
		var pickup := coin_scene.instantiate()
		parent.add_child(pickup)
		if pickup.has_method("launch_from"):
			pickup.call("launch_from", global_position)
		elif pickup is Node2D:
			pickup.global_position = global_position


func _build_ellipse_points(radius_x: float, radius_y: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _build_floor_wave_polygon(width: float, height: float) -> PackedVector2Array:
	var half_width := width * 0.5
	var half_height := height * 0.5
	return PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height),
	])


func _get_current_gravity() -> float:
	if state == &"quake_jump" or state == &"anti_pogo_launch":
		if velocity.y < 0.0:
			return quake_rise_gravity
		return quake_fall_gravity
	return gravity


func _get_jump_animation_frame_time() -> float:
	if velocity.y < 0.0:
		return jump_rise_animation_frame_time
	return jump_fall_animation_frame_time


func _start_intro_effect() -> void:
	intro_time_left = intro_effect_duration
	intro_elapsed = 0.0
	intro_next_ring_time = 0.0
	state = &"intro"
	_make_player_face_boss()
	GameState.set_input_locked(true)
	_set_damage_area_enabled(false)
	_set_quake_damage_area_enabled(false)
	_set_windup_effect(true, Color(0.9, 1.0, 1.0, 0.72))
	_set_rest_effect(false)
	_play_intro_sfx()


func _update_intro_effect(delta: float) -> void:
	intro_time_left -= delta
	intro_elapsed += delta
	intro_next_ring_time -= delta

	var progress := clampf(intro_elapsed / maxf(intro_effect_duration, 0.001), 0.0, 1.0)
	if intro_next_ring_time <= 0.0:
		_spawn_intro_ring()
		intro_next_ring_time = lerpf(intro_ring_start_interval, intro_ring_end_interval, progress)
	var shake_strength := lerpf(intro_min_shake_strength, intro_max_shake_strength, progress)
	var player := target
	if player == null:
		player = _find_player()
	if player != null and player.has_method("_start_camera_shake"):
		player.call("_start_camera_shake", 0.18, shake_strength)

	if intro_time_left <= 0.0:
		GameState.set_input_locked(false)
		_stop_intro_sfx()
		_set_windup_effect(false)
		idle_decision_left = idle_decision_time
		state = &"idle"


func _make_player_face_boss() -> void:
	var player := _find_player()
	if player != null and player.has_method("face_position"):
		player.call("face_position", global_position)


func _spawn_intro_ring() -> void:
	var burst := Node2D.new()
	burst.name = "IntroBurst"
	burst.z_index = 200
	add_child(burst)

	var glow := Polygon2D.new()
	glow.name = "CenterGlow"
	glow.color = Color(1.0, 0.96, 0.82, 0.06)
	glow.polygon = _build_circle_polygon(intro_center_glow_radius, 48)
	glow.z_index = 198
	burst.add_child(glow)

	_add_intro_spikes(burst)

	var ring := Line2D.new()
	ring.name = "IntroRing"
	ring.closed = true
	ring.width = intro_ring_width
	ring.default_color = Color(1.0, 1.0, 1.0, 0.24)
	ring.gradient = _build_intro_ring_gradient()
	ring.z_index = 200
	ring.points = _build_ring_points(intro_ring_radius, 128)
	burst.add_child(ring)

	var tween := create_tween()
	burst.scale = Vector2(0.12, 0.12)
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * intro_ring_max_scale, 0.72)
	tween.tween_property(burst, "modulate:a", 0.0, 0.72)
	tween.set_parallel(false)
	tween.tween_callback(_queue_free_instance_id.bind(burst.get_instance_id()))


func _build_ring_points(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _add_intro_spikes(parent: Node2D) -> void:
	var count := maxi(3, intro_spike_count)
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var half_width := intro_spike_angle_width * randf_range(0.75, 1.2)
		var inner_radius := intro_spike_inner_radius * randf_range(0.85, 1.15)
		var outer_radius := intro_spike_outer_radius * randf_range(0.85, 1.2)
		var spike := Polygon2D.new()
		spike.name = "IntroSpike"
		spike.color = Color(1.0, 1.0, 1.0, 0.08)
		spike.z_index = 199
		spike.polygon = PackedVector2Array([
			Vector2(cos(angle - half_width), sin(angle - half_width)) * inner_radius,
			Vector2(cos(angle), sin(angle)) * outer_radius,
			Vector2(cos(angle + half_width), sin(angle + half_width)) * inner_radius,
		])
		parent.add_child(spike)


func _build_circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _play_intro_sfx() -> void:
	if intro_sfx == null:
		return
	if intro_audio == null:
		intro_audio = AudioStreamPlayer.new()
		intro_audio.name = "IntroAudio"
		add_child(intro_audio)
	intro_audio.stream = intro_sfx
	intro_audio.bus = "SFX"
	intro_audio.volume_db = intro_sfx_volume_db
	intro_audio.play()


func _stop_intro_sfx() -> void:
	if intro_audio != null and intro_audio.playing:
		intro_audio.stop()


func _play_ink_sfx() -> void:
	if ink_sfx == null:
		return

	var audio := AudioStreamPlayer.new()
	audio.name = "InkAudio"
	audio.stream = ink_sfx
	audio.bus = "SFX"
	audio.volume_db = ink_sfx_volume_db
	audio.finished.connect(_queue_free_instance_id.bind(audio.get_instance_id()))
	add_child(audio)
	audio.play()


func _queue_free_instance_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Node:
		node.queue_free()


func _build_intro_ring_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.42, 0.7, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.0),
		Color(1.0, 1.0, 1.0, 0.22),
		Color(0.86, 0.96, 1.0, 0.08),
		Color(1.0, 1.0, 1.0, 0.18),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	return gradient


func _begin_random_special_after_dash() -> void:
	if _must_use_non_quake_attack():
		_begin_ink_attack()
		return

	if _must_use_close_attack() or _is_target_close():
		_begin_quake_jump()
	else:
		_begin_ink_attack()


func _begin_random_attack() -> void:
	if target == null or not _can_dash_attack():
		state = &"idle"
		return

	if _must_use_non_quake_attack():
		if _is_target_close():
			_begin_dash_attack()
		else:
			_begin_ink_attack()
		return

	if _must_use_close_attack() or _is_target_close():
		if randf() < 0.5:
			_begin_dash_attack()
		else:
			_begin_quake_jump()
	else:
		_begin_ink_attack()


func _must_use_close_attack() -> bool:
	return ranged_attack_count >= ranged_attacks_before_forced_close


func _must_use_non_quake_attack() -> bool:
	return quake_attack_count >= quake_attacks_before_forced_other


func _reset_ranged_attack_count() -> void:
	ranged_attack_count = 0
	ranged_attacks_before_forced_close = _roll_ranged_attacks_before_forced_close()


func _reset_quake_attack_count() -> void:
	quake_attack_count = 0
	quake_attacks_before_forced_other = _roll_quake_attacks_before_forced_other()


func _roll_ranged_attacks_before_forced_close() -> int:
	return randi_range(min_ranged_attacks_before_forced_close, max_ranged_attacks_before_forced_close)


func _roll_quake_attacks_before_forced_other() -> int:
	return randi_range(min_quake_attacks_before_forced_other, max_quake_attacks_before_forced_other)


func _roll_attack_cycles_before_rest() -> int:
	var minimum := maxi(1, min_attack_cycles_before_rest)
	var maximum := maxi(minimum, max_attack_cycles_before_rest)
	return randi_range(minimum, maximum)


func _roll_dash_combo_count() -> int:
	var minimum := dash_combo_phase_one_min
	var maximum := dash_combo_phase_one_max
	minimum = maxi(1, minimum)
	maximum = maxi(minimum, maximum)
	return randi_range(minimum, maximum)


func _is_target_close() -> bool:
	if target == null:
		return false
	return absf(target.global_position.x - global_position.x) <= close_attack_range


func _shoot_one_ink() -> void:
	if ink_projectile_scene == null:
		return

	var parent := get_parent()
	if parent == null:
		return

	var projectile := ink_projectile_scene.instantiate()
	parent.add_child(projectile)
	if projectile is Node2D:
		var random_height := randf_range(ink_projectile_min_height, ink_projectile_max_height)
		if target != null:
			var aimed_height := clampf(target.global_position.y - global_position.y, ink_projectile_min_height, ink_projectile_max_height)
			random_height = lerpf(random_height, aimed_height, 0.45)
		projectile.global_position = global_position + Vector2(74.0 * direction, random_height)
	var speed_multiplier := randf_range(ink_projectile_min_speed_multiplier, ink_projectile_max_speed_multiplier)
	var projectile_speed := ink_projectile_speed * speed_multiplier
	if projectile.has_method("launch_wave"):
		var wave_amplitude := randf_range(ink_projectile_min_wave_amplitude, ink_projectile_max_wave_amplitude)
		var wave_frequency := randf_range(ink_projectile_min_wave_frequency, ink_projectile_max_wave_frequency)
		var wave_phase := randf_range(0.0, TAU)
		projectile.call("launch_wave", direction, contact_damage, projectile_speed, wave_amplitude, wave_frequency, wave_phase, self)
	_play_ink_sfx()


func _configure_dash_hitbox() -> void:
	damage_area.position = Vector2(dash_hitbox_offset.x * direction, dash_hitbox_offset.y)
	damage_area.scale = Vector2.ONE
	if damage_shape != null and damage_shape.shape is RectangleShape2D:
		var rect_shape := damage_shape.shape as RectangleShape2D
		rect_shape.size = dash_hitbox_size


func _start_dash_telegraph() -> void:
	_clear_attack_telegraph()
	var parent := get_parent()
	if parent == null:
		return

	telegraph_node = Node2D.new()
	telegraph_node.name = "DashTelegraph"
	telegraph_node.z_index = 210
	parent.add_child(telegraph_node)

	telegraph_line = Line2D.new()
	telegraph_line.name = "DashLane"
	telegraph_line.width = 9.0
	telegraph_line.default_color = Color(1.0, 0.26, 0.16, 0.56)
	telegraph_node.add_child(telegraph_line)
	_update_dash_telegraph()

	var rail := Line2D.new()
	rail.name = "DashLaneCore"
	rail.width = 3.0
	rail.default_color = Color(1.0, 0.95, 0.72, 0.82)
	rail.points = telegraph_line.points
	telegraph_node.add_child(rail)

	telegraph_tween = create_tween()
	telegraph_tween.set_loops()
	telegraph_tween.tween_property(telegraph_node, "modulate:a", 0.32, 0.12)
	telegraph_tween.tween_property(telegraph_node, "modulate:a", 1.0, 0.12)


func _update_dash_telegraph() -> void:
	if telegraph_line == null or not is_instance_valid(telegraph_line):
		return
	var y := global_position.y + dash_telegraph_y_offset
	var start := global_position + Vector2(24.0 * direction, dash_telegraph_y_offset)
	var end := Vector2(global_position.x + dash_telegraph_length * direction, y)
	telegraph_line.points = PackedVector2Array([start, end])
	for child in telegraph_node.get_children():
		if child is Line2D and child != telegraph_line:
			child.points = telegraph_line.points


func _start_ink_telegraph() -> void:
	_clear_attack_telegraph()
	var parent := get_parent()
	if parent == null:
		return
	telegraph_node = Node2D.new()
	telegraph_node.name = "InkTelegraph"
	telegraph_node.z_index = 210
	parent.add_child(telegraph_node)

	var origin := global_position + Vector2(74.0 * direction, 0.0)
	for index in range(3):
		var line := Line2D.new()
		line.name = "InkAimLine"
		line.width = 4.0
		line.default_color = Color(0.34, 0.82, 1.0, 0.55)
		var y_offset := lerpf(-58.0, 58.0, float(index) / 2.0)
		line.points = PackedVector2Array([
			origin,
			origin + Vector2(180.0 * direction, y_offset),
		])
		telegraph_node.add_child(line)

	telegraph_tween = create_tween()
	telegraph_tween.set_loops()
	telegraph_tween.tween_property(telegraph_node, "modulate:a", 0.28, 0.16)
	telegraph_tween.tween_property(telegraph_node, "modulate:a", 1.0, 0.16)


func _start_quake_telegraph() -> void:
	_clear_attack_telegraph()
	var parent := get_parent()
	if parent == null:
		return
	telegraph_node = Node2D.new()
	telegraph_node.name = "QuakeTelegraph"
	telegraph_node.z_index = 210
	parent.add_child(telegraph_node)
	telegraph_node.global_position = global_position + Vector2(0.0, quake_wave_y_offset)

	var ground := Line2D.new()
	ground.name = "QuakeDamageWidth"
	ground.width = 7.0
	ground.default_color = Color(1.0, 0.86, 0.22, 0.58)
	ground.points = PackedVector2Array([
		Vector2(-quake_damage_width * 0.5, 0.0),
		Vector2(quake_damage_width * 0.5, 0.0),
	])
	telegraph_node.add_child(ground)

	var ring := Line2D.new()
	ring.name = "QuakeWarningRing"
	ring.closed = true
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.94, 0.42, 0.55)
	ring.points = _build_ellipse_points(quake_wave_width * 0.35, quake_wave_height * 0.65, 64)
	telegraph_node.add_child(ring)

	telegraph_tween = create_tween()
	telegraph_tween.set_loops()
	telegraph_tween.tween_property(telegraph_node, "scale", Vector2(1.08, 1.0), 0.18)
	telegraph_tween.tween_property(telegraph_node, "scale", Vector2.ONE, 0.18)


func _clear_attack_telegraph() -> void:
	if telegraph_tween != null and telegraph_tween.is_valid():
		telegraph_tween.kill()
	telegraph_tween = null
	telegraph_line = null
	if telegraph_node != null and is_instance_valid(telegraph_node):
		telegraph_node.queue_free()
	telegraph_node = null


func _apply_windup_pose(progress: float, warning_color: Color) -> void:
	progress = clampf(progress, 0.0, 1.0)
	var pulse := 0.5 + sin(progress * TAU * 3.0) * 0.5
	sprite.scale = default_sprite_scale * Vector2(1.0 + progress * 0.18, 1.0 - progress * 0.1)
	sprite.position.x = -direction * progress * 10.0
	sprite.modulate = default_sprite_modulate.lerp(warning_color, 0.22 + pulse * 0.28)


func _apply_ready_pose(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	var pulse := 0.5 + sin(progress * TAU * 2.0) * 0.5
	sprite.scale = default_sprite_scale * Vector2(1.0 + progress * 0.05, 1.0 - progress * 0.035)
	sprite.position = Vector2(-direction * progress * 3.0, progress * 3.0)
	sprite.modulate = default_sprite_modulate.lerp(Color(1.0, 0.94, 0.72, 1.0), 0.12 + pulse * 0.1)


func _apply_rest_pose() -> void:
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.5
	sprite.scale = default_sprite_scale * Vector2(1.08, 0.9)
	sprite.position = Vector2(0.0, 12.0 + pulse * 2.0)
	sprite.modulate = default_sprite_modulate.lerp(Color(0.62, 0.82, 1.0, 1.0), 0.28 + pulse * 0.12)


func _set_windup_effect(enabled: bool, color := Color(1.0, 0.92, 0.62, 0.78)) -> void:
	if windup_particles == null:
		return
	windup_particles.color = color
	windup_particles.emitting = enabled


func _set_rest_effect(enabled: bool) -> void:
	if rest_breath_particles == null:
		return
	rest_breath_particles.emitting = enabled


func _play_quake_impact_effect() -> void:
	if quake_impact_particles == null:
		return
	quake_impact_particles.global_position = global_position + Vector2(0.0, quake_damage_hitbox_y_offset)
	quake_impact_particles.restart()
	quake_impact_particles.emitting = true


func _reset_sprite_pose() -> void:
	sprite.scale = default_sprite_scale
	sprite.position = Vector2.ZERO
	sprite.modulate = default_sprite_modulate


func _can_dash_attack() -> bool:
	if target == null:
		return false

	var offset := target.global_position - global_position
	return absf(offset.x) <= attack_range and absf(offset.y) <= vertical_tolerance


func _find_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player

	var scene := get_tree().current_scene
	if scene == null:
		return null

	player = scene.find_child("Player", true, false)
	if player is Node2D:
		return player
	return null


func _face_target() -> void:
	if target == null:
		return

	var new_direction := signf(target.global_position.x - global_position.x)
	if is_zero_approx(new_direction):
		return

	direction = int(new_direction)
	_sync_facing()


func _sync_facing() -> void:
	_apply_sprite_facing()
	_configure_dash_hitbox()


func _apply_sprite_facing() -> void:
	sprite.flip_h = direction > 0
	if state == &"dash" and dash_animation_flipped:
		sprite.flip_h = not sprite.flip_h


func _play_dash_end_impact() -> void:
	DEMO_COMBAT_JUICE.shake_camera(self, 0.16, dash_end_impact_shake)


func _start_dash_animation() -> void:
	sprite.scale = default_sprite_scale
	dash_frame_index = 0
	dash_frame_time_left = dash_animation_frame_time
	_apply_sprite_facing()
	if not dash_frames.is_empty():
		sprite.texture = dash_frames[dash_frame_index]
	_spawn_dash_afterimage(0.32)


func _spawn_dash_afterimage(duration: float) -> void:
	if sprite == null or sprite.texture == null:
		return
	var parent := get_parent()
	if parent == null:
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.is_node_ready() or Engine.get_process_frames() < 3:
		return

	var ghost := Sprite2D.new()
	ghost.name = "BossDashAfterimage"
	ghost.texture = sprite.texture
	ghost.centered = sprite.centered
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position - Vector2(float(direction) * 28.0, 0.0)
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale
	ghost.z_index = z_index + 1
	ghost.modulate = Color(1.0, 0.62, 0.36, 0.32)
	parent.add_child(ghost)

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "global_position", ghost.global_position - Vector2(float(direction) * 52.0, 0.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost, "scale", ghost.scale * 1.04, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(Callable(ghost, "queue_free"))


func _stop_dash_animation() -> void:
	if default_texture != null:
		sprite.texture = default_texture
	_apply_sprite_facing()


func _update_boss_animation(delta: float) -> void:
	if state == &"dash":
		_update_dash_animation(delta)
		return
	if state == &"quake_jump" or state == &"quake_recover" or state == &"anti_pogo_launch" or state == &"anti_pogo_recover":
		_update_jump_animation(delta)
		return
	if state == &"ink_fire" and throw_animation_active:
		_update_throw_animation(delta)
		return
	if state == &"rest":
		if sprite.texture != default_texture and default_texture != null:
			sprite.texture = default_texture
		return

	if sprite.texture != default_texture:
		_stop_special_animation()


func _update_dash_animation(delta: float) -> void:
	if dash_frames.is_empty():
		return

	dash_frame_time_left -= delta
	if dash_frame_time_left > 0.0:
		return

	dash_frame_time_left = dash_animation_frame_time
	dash_frame_index = (dash_frame_index + 1) % dash_frames.size()
	sprite.texture = dash_frames[dash_frame_index]


func _start_jump_animation() -> void:
	sprite.scale = default_sprite_scale
	jump_rise_frame_index = 0
	jump_fall_frame_index = 3
	jump_frame_time_left = _get_jump_animation_frame_time()
	_apply_sprite_facing()
	if not jump_frames.is_empty():
		sprite.texture = jump_frames[jump_rise_frame_index]


func _update_jump_animation(delta: float) -> void:
	if jump_frames.is_empty():
		return

	jump_frame_time_left -= delta
	if jump_frame_time_left > 0.0:
		return

	jump_frame_time_left = _get_jump_animation_frame_time()
	if velocity.y < 0.0:
		jump_rise_frame_index = mini(jump_rise_frame_index + 1, mini(2, jump_frames.size() - 1))
		sprite.texture = jump_frames[jump_rise_frame_index]
	else:
		if jump_frames.size() < 5:
			sprite.texture = jump_frames[jump_frames.size() - 1]
			return
		jump_fall_frame_index = mini(jump_fall_frame_index + 1, 4)
		sprite.texture = jump_frames[jump_fall_frame_index]


func _stop_special_animation() -> void:
	_reset_sprite_pose()
	if default_texture != null:
		sprite.texture = default_texture
	throw_animation_active = false
	_apply_sprite_facing()


func _load_dash_frames() -> void:
	dash_frames.clear()
	for path in DASH_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			dash_frames.append(texture)


func _load_jump_frames() -> void:
	jump_frames.clear()
	for path in JUMP_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			jump_frames.append(texture)


func _start_throw_animation() -> void:
	throw_animation_active = true
	sprite.scale = default_sprite_scale * throw_animation_scale_multiplier
	throw_frame_index = 0
	throw_frame_time_left = throw_animation_frame_time
	_apply_sprite_facing()
	if not throw_frames.is_empty():
		sprite.texture = throw_frames[throw_frame_index]


func _update_throw_animation(delta: float) -> void:
	if throw_frames.is_empty():
		throw_animation_active = false
		return

	throw_frame_time_left -= delta
	if throw_frame_time_left > 0.0:
		return

	throw_frame_time_left = throw_animation_frame_time
	throw_frame_index += 1
	if throw_frame_index >= throw_frames.size():
		throw_animation_active = false
		return
	sprite.texture = throw_frames[throw_frame_index]


func _load_throw_frames() -> void:
	throw_frames.clear()
	for path in THROW_FRAME_PATHS:
		var texture := load(path)
		if texture is Texture2D:
			throw_frames.append(texture)


func _set_damage_area_enabled(enabled: bool) -> void:
	damage_area.set_deferred("monitoring", enabled)
	damage_shape.set_deferred("disabled", not enabled)


func _setup_quake_damage_area() -> void:
	if quake_damage_area == null:
		quake_damage_area = Area2D.new()
		quake_damage_area.name = "QuakeDamageArea"
		quake_damage_area.collision_layer = 32
		quake_damage_area.collision_mask = 16
		quake_damage_area.monitoring = false
		quake_damage_area.monitorable = false
		add_child(quake_damage_area)

	if quake_damage_shape == null:
		quake_damage_shape = CollisionShape2D.new()
		quake_damage_shape.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		quake_damage_shape.shape = shape
		quake_damage_area.add_child(quake_damage_shape)

	quake_damage_shape.disabled = true
	_configure_quake_damage_area()


func _configure_quake_damage_area() -> void:
	if quake_damage_area == null or quake_damage_shape == null:
		return

	quake_damage_area.top_level = true
	quake_damage_area.global_position = global_position + Vector2(0.0, quake_damage_hitbox_y_offset)
	quake_damage_area.scale = Vector2.ONE
	if quake_damage_shape.shape is RectangleShape2D:
		var rect_shape := quake_damage_shape.shape as RectangleShape2D
		rect_shape.size = Vector2(quake_damage_width, quake_damage_hitbox_height)


func _configure_anti_pogo_damage_area() -> void:
	if quake_damage_area == null or quake_damage_shape == null:
		return

	quake_damage_area.top_level = true
	quake_damage_area.global_position = global_position + Vector2(0.0, anti_pogo_damage_y_offset)
	quake_damage_area.scale = Vector2.ONE
	if quake_damage_shape.shape is RectangleShape2D:
		var rect_shape := quake_damage_shape.shape as RectangleShape2D
		rect_shape.size = Vector2(anti_pogo_damage_width, anti_pogo_damage_height)


func _set_quake_damage_area_enabled(enabled: bool) -> void:
	if quake_damage_area == null or quake_damage_shape == null:
		return

	quake_damage_area.set_deferred("monitoring", enabled)
	quake_damage_shape.set_deferred("disabled", not enabled)


func _damage_quake_area_overlaps() -> void:
	if quake_damage_area == null:
		return

	for area in quake_damage_area.get_overlapping_areas():
		var receiver := _find_damage_receiver(area)
		if receiver == null or receiver == self:
			continue
		if receiver is CharacterBody2D and not receiver.is_on_floor():
			continue
		if receiver.has_method("take_quake_damage"):
			receiver.call("take_quake_damage", quake_damage)
		elif receiver.has_method("take_damage"):
			receiver.call("take_damage", quake_damage, global_position)


func _damage_anti_pogo_area_overlaps() -> void:
	if quake_damage_area == null:
		return

	var damaged: Array[Node] = []
	for area in quake_damage_area.get_overlapping_areas():
		var receiver := _find_damage_receiver(area)
		if receiver == null or receiver == self or damaged.has(receiver):
			continue
		damaged.append(receiver)
		receiver.call("take_damage", anti_pogo_damage, global_position)

	if target != null and target.has_method("take_damage") and not damaged.has(target):
		var area_center := global_position + Vector2(0.0, anti_pogo_damage_y_offset)
		var offset := target.global_position - area_center
		if absf(offset.x) <= anti_pogo_damage_width * 0.5 and absf(offset.y) <= anti_pogo_damage_height * 0.5:
			target.call("take_damage", anti_pogo_damage, global_position)


func _setup_body_contact_area() -> void:
	if not body_contact_damage_enabled:
		return

	body_contact_area = get_node_or_null("BodyContactArea") as Area2D
	if body_contact_area == null:
		if collision_shape == null or collision_shape.shape == null:
			return
		body_contact_area = Area2D.new()
		body_contact_area.name = "BodyContactArea"
		add_child(body_contact_area)

	body_contact_area.collision_layer = 32
	body_contact_area.collision_mask = 16
	body_contact_area.set_collision_mask_value(PLAYER_BODY_COLLISION_LAYER_NUMBER, true)
	body_contact_area.monitoring = true
	body_contact_area.monitorable = false
	if not body_contact_area.area_entered.is_connected(_on_body_contact_area_entered):
		body_contact_area.area_entered.connect(_on_body_contact_area_entered)
	if not body_contact_area.area_exited.is_connected(_on_body_contact_area_exited):
		body_contact_area.area_exited.connect(_on_body_contact_area_exited)
	if not body_contact_area.body_entered.is_connected(_on_body_contact_body_entered):
		body_contact_area.body_entered.connect(_on_body_contact_body_entered)

	body_contact_shape = body_contact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_contact_shape == null and collision_shape != null and collision_shape.shape != null:
		body_contact_shape = CollisionShape2D.new()
		body_contact_shape.name = "CollisionShape2D"
		body_contact_shape.shape = collision_shape.shape
		body_contact_shape.position = collision_shape.position
		body_contact_shape.rotation = collision_shape.rotation
		body_contact_shape.scale = collision_shape.scale
		body_contact_area.add_child(body_contact_shape)


func _update_body_contact_damage(delta: float) -> void:
	if intro_time_left > 0.0 or body_contact_area == null:
		return
	if not body_contact_area.monitoring:
		return

	for overlapping_area in body_contact_area.get_overlapping_areas():
		if not body_contact_targets.has(overlapping_area):
			body_contact_targets.append(overlapping_area)

	for index in range(body_contact_targets.size() - 1, -1, -1):
		var area := body_contact_targets[index]
		if area == null or not is_instance_valid(area) or not area.is_inside_tree():
			body_contact_targets.remove_at(index)
	if not _is_body_contact_damage_active():
		return

	body_contact_damage_cooldown = maxf(body_contact_damage_cooldown - delta, 0.0)
	if body_contact_damage_cooldown > 0.0:
		return

	var damaged := false
	for area in body_contact_targets:
		if _damage_contact_target(area):
			damaged = true
			break
	if not damaged:
		for body in body_contact_area.get_overlapping_bodies():
			if _damage_body_contact_receiver(body):
				damaged = true
				break
	if not damaged:
		damaged = _damage_player_body_contact_if_overlapping()
	if damaged:
		body_contact_damage_cooldown = body_contact_damage_interval


func _on_body_contact_area_entered(area: Area2D) -> void:
	if intro_time_left > 0.0:
		return
	if not body_contact_targets.has(area):
		body_contact_targets.append(area)
	if _is_body_contact_damage_active() and body_contact_damage_cooldown <= 0.0:
		if _damage_contact_target(area):
			body_contact_damage_cooldown = body_contact_damage_interval


func _on_body_contact_area_exited(area: Area2D) -> void:
	body_contact_targets.erase(area)


func _on_body_contact_body_entered(body: Node2D) -> void:
	if intro_time_left > 0.0:
		return
	if _is_body_contact_damage_active() and body_contact_damage_cooldown <= 0.0:
		if _damage_body_contact_receiver(body):
			body_contact_damage_cooldown = body_contact_damage_interval


func _damage_contact_target(target_area: Area2D) -> bool:
	if not _is_body_contact_damage_active():
		return false
	if target_area == null or not is_instance_valid(target_area) or not target_area.is_inside_tree():
		return false

	var receiver := _find_damage_receiver(target_area)
	if receiver == null or receiver == self:
		return false

	return _damage_body_contact_receiver(receiver)


func _damage_body_contact_receiver(receiver: Node) -> bool:
	if receiver == null or receiver == self or not is_instance_valid(receiver) or not receiver.has_method("take_damage"):
		return false
	receiver.call("take_damage", contact_damage, global_position)
	if receiver == target or receiver.is_in_group("player"):
		_set_player_body_collision_ignored(player_body_collision_ignore_time)
	return true


func _damage_player_body_contact_if_overlapping() -> bool:
	if not _is_body_contact_damage_active():
		return false
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		target = _find_player()
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return false
	if not (target is Node2D):
		return false
	if not _does_player_body_overlap_contact_zone(target):
		return false
	return _damage_body_contact_receiver(target)


func _does_player_body_overlap_contact_zone(player_node: Node2D) -> bool:
	var boss_rect := _shape_global_rect(body_contact_shape)
	if boss_rect.size == Vector2.ZERO:
		boss_rect = _shape_global_rect(collision_shape)
	if boss_rect.size != Vector2.ZERO:
		boss_rect = boss_rect.grow(body_contact_damage_margin)
	var player_shape := player_node.find_child("CollisionShape2D", true, false) as CollisionShape2D
	var player_rect := _shape_global_rect(player_shape)
	if boss_rect.size == Vector2.ZERO or player_rect.size == Vector2.ZERO:
		return global_position.distance_to(player_node.global_position) <= 145.0
	return boss_rect.intersects(player_rect, true)


func _shape_global_rect(shape_node: CollisionShape2D) -> Rect2:
	if shape_node == null or shape_node.shape == null:
		return Rect2()

	var shape_size := Vector2.ZERO
	if shape_node.shape is RectangleShape2D:
		shape_size = (shape_node.shape as RectangleShape2D).size
	elif shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		shape_size = Vector2(capsule.radius * 2.0, capsule.height)
	elif shape_node.shape is CircleShape2D:
		var circle := shape_node.shape as CircleShape2D
		shape_size = Vector2(circle.radius * 2.0, circle.radius * 2.0)

	if shape_size == Vector2.ZERO:
		return Rect2()

	var scaled_size := shape_size * shape_node.global_scale.abs()
	return Rect2(shape_node.global_position - scaled_size * 0.5, scaled_size)


func _is_falling_jump_body_contact() -> bool:
	return (state == &"quake_jump" or state == &"anti_pogo_launch") and velocity.y >= 0.0


func _is_body_contact_damage_active() -> bool:
	return not is_defeated and intro_time_left <= 0.0


func _damage_jump_body_collisions(was_falling_jump: bool) -> void:
	if not was_falling_jump or intro_time_left > 0.0:
		return

	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision == null or collision.get_normal().y > -0.35:
			continue

		var collider: Object = collision.get_collider()
		if not (collider is Node):
			continue

		var receiver: Node = _find_damage_receiver(collider as Node)
		if receiver == null or receiver == self:
			continue
		if receiver.has_method("take_damage"):
			receiver.call("take_damage", contact_damage, global_position)
			body_contact_damage_cooldown = body_contact_damage_interval


func _resolve_player_floor_collisions() -> void:
	if intro_time_left > 0.0:
		return

	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision == null or collision.get_normal().y > -0.35:
			continue

		var receiver := _damage_receiver_from_collision(collision)
		if receiver == null or receiver == self:
			continue

		if receiver.has_method("take_damage"):
			receiver.call("take_damage", contact_damage, global_position)
		body_contact_damage_cooldown = body_contact_damage_interval
		_set_player_body_collision_ignored(player_body_collision_ignore_time)
		return


func _update_last_solid_floor_y() -> void:
	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision == null or collision.get_normal().y > -0.35:
			continue

		var receiver := _damage_receiver_from_collision(collision)
		if receiver != null and receiver != self:
			continue

		last_solid_floor_y = global_position.y
		return


func _snap_to_last_solid_floor_before_jump() -> void:
	if last_solid_floor_y >= 99999999.0:
		return
	if global_position.y >= last_solid_floor_y - 24.0:
		return

	if target != null and target.has_method("take_damage"):
		target.call("take_damage", contact_damage, global_position)
	global_position.y = last_solid_floor_y


func _damage_receiver_from_collision(collision: KinematicCollision2D) -> Node:
	var collider: Object = collision.get_collider()
	if not (collider is Node):
		return null
	return _find_damage_receiver(collider as Node)


func _update_player_body_collision_ignore(delta: float) -> void:
	if player_body_collision_ignore_left <= 0.0:
		return

	player_body_collision_ignore_left -= delta
	if player_body_collision_ignore_left <= 0.0:
		collision_mask = normal_collision_mask


func _set_player_body_collision_ignored(duration: float) -> void:
	if normal_collision_mask == 0:
		normal_collision_mask = collision_mask
	collision_mask = normal_collision_mask
	set_collision_mask_value(PLAYER_BODY_COLLISION_LAYER_NUMBER, false)
	player_body_collision_ignore_left = maxf(player_body_collision_ignore_left, duration)


func _on_damage_area_entered(area: Area2D) -> void:
	if state != &"dash":
		return

	_damage_contact_target(area)



func _find_damage_receiver(target_node: Node) -> Node:
	var current: Node = target_node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _flash(color: Color = Color(1.0, 0.25, 0.25), hold_time: float = 0.05, fade_time: float = 0.12) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", color, hold_time)
	tween.tween_property(sprite, "modulate", default_sprite_modulate, fade_time)
