extends Area2D

@export var max_health := 2
@export var damage := 1
@export var touch_damage := 1
@export var attack_interval_min := 2.5
@export var attack_interval_max := 5.0
@export var attack_warning_time := 0.8
@export var attack_active_time := 0.45
@export var top_tentacle := false
@export var top_visible_time := 2.2
@export var top_hidden_time_min := 1.5
@export var top_hidden_time_max := 3.0
@export var timed_cycle_enabled := false
@export var timed_cycle_hidden_time := 5.0
@export var timed_cycle_idle_time := 8.0
@export var timed_cycle_attack_before_hide := false
@export var timed_cycle_spawn_warning_time := 0.0
@export var spawn_warning_color := Color(1.0, 1.0, 1.0, 0.45)
@export var max_visible_timed_cycle_siblings := 0
@export var warning_color := Color(1.0, 0.25, 0.15, 0.45)
@export var active_color := Color(1.0, 0.1, 0.05, 0.75)
@export var attack_visual_tint := true
@export var align_attack_visual_to_visual := false
@export var hide_visual_during_attack := false
@export var show_fan_warning := false
@export var corner_prep_enabled := true
@export var corner_prep_sequence_index := -1
@export var corner_prep_frame_time := 0.07
@export var corner_prep_random_delay_min := 0.0
@export var corner_prep_random_delay_max := 0.22
@export var corner_prep_attack_link_frame := 4
@export var attack_retry_wait_min := 0.3
@export var attack_retry_wait_max := 0.8

const CORNER_PREP_SEQUENCES := [
	[4, 5, 6, 7, 6, 5, 4],
	[6, 7, 8, 9, 8, 7, 6, 5, 4],
	[3, 4, 5, 6, 7, 6, 5, 4],
	[8, 7, 6, 5, 4],
]

var health := 0
var manager: Node
var _dead := false
var _active := true
var _hit_targets := {}
var _touch_targets := {}
var _flash_tween: Tween
var _cycle_version := 0
var _spawn_warning_active := false
var attack_frame_hitboxes: Array[Node] = []
var idle_frame_hitboxes: Array[Node] = []
var idle_base_shape: CollisionShape2D
var _last_idle_hitbox_frame := -1

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
@onready var attack_visual: CanvasItem = get_node_or_null("AttackWarning") as CanvasItem
@onready var fan_warning_visual: CanvasItem = get_node_or_null("FanWarning") as CanvasItem
@onready var corner_attack_visual: CanvasItem = get_node_or_null("CornerAttack") as CanvasItem
@onready var attack_shape: Node = _get_attack_collision_node()


func _ready() -> void:
	health = max_health
	collision_layer = 4
	collision_mask = 18
	if not area_entered.is_connected(_on_touch_area_entered):
		area_entered.connect(_on_touch_area_entered)
	if not area_exited.is_connected(_on_touch_area_exited):
		area_exited.connect(_on_touch_area_exited)
	if not body_entered.is_connected(_on_touch_body_entered):
		body_entered.connect(_on_touch_body_entered)
	if not body_exited.is_connected(_on_touch_body_exited):
		body_exited.connect(_on_touch_body_exited)
	if attack_area != null:
		attack_area.collision_layer = 32
		attack_area.collision_mask = 18
		attack_area.monitoring = false
		attack_area.area_entered.connect(_on_attack_area_entered)
		attack_area.body_entered.connect(_on_attack_body_entered)
	if attack_shape != null:
		attack_shape.set("disabled", true)
	_collect_attack_frame_hitboxes()
	_disable_attack_frame_hitboxes()
	idle_base_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_collect_idle_frame_hitboxes()
	_update_idle_frame_hitbox()
	if attack_visual != null:
		attack_visual.visible = false
	if corner_attack_visual != null:
		corner_attack_visual.visible = false
	call_deferred("_attack_loop")
	if timed_cycle_enabled:
		_set_body_visible(false)
		_start_timed_cycle()
	if top_tentacle and not timed_cycle_enabled:
		call_deferred("_top_visibility_loop")


func _physics_process(_delta: float) -> void:
	_update_idle_frame_hitbox()


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func respawn() -> void:
	_cycle_version += 1
	health = max_health
	_dead = false
	_active = true
	_touch_targets.clear()
	_set_body_visible(not timed_cycle_enabled)
	if visual != null:
		visual.modulate = Color.WHITE
	if attack_visual != null:
		attack_visual.visible = false
	if corner_attack_visual != null:
		corner_attack_visual.visible = false
	_set_attack_enabled(false)
	if timed_cycle_enabled:
		_start_timed_cycle()


func set_active(active: bool) -> void:
	_active = active
	if not active:
		_set_attack_enabled(false)
		_hide_attack_visual()
		_hide_corner_attack_visual()
	if timed_cycle_enabled:
		if not active or _dead:
			_set_body_visible(false)
	else:
		_set_body_visible(active and not _dead)


func is_dead() -> bool:
	return _dead


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if _dead or not _active:
		return

	health -= amount
	if health > 0:
		_flash_hit()
		return

	_die()


func _die() -> void:
	_dead = true
	_active = false
	_cycle_version += 1
	_touch_targets.clear()
	_set_attack_enabled(false)
	_hide_attack_visual()
	_hide_corner_attack_visual()
	_set_body_visible(false)
	if manager != null and manager.has_method("on_tentacle_died"):
		manager.call("on_tentacle_died", self)


func _attack_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(attack_interval_min, attack_interval_max)).timeout
		if not _active or _dead or not visible or _spawn_warning_active:
			continue
		if corner_attack_visual != null:
			await _corner_attack_once()
		else:
			await _attack_once()


func _wait_for_tentacle_attack_slot() -> bool:
	if manager == null or not manager.has_method("can_tentacle_attack"):
		return true

	while is_inside_tree():
		if _dead or not _active or not visible:
			return false
		if bool(manager.call("can_tentacle_attack", self)):
			return true
		await get_tree().create_timer(randf_range(attack_retry_wait_min, attack_retry_wait_max)).timeout

	return false


func _notify_tentacle_attack_finished(attack_slot_claimed: bool) -> void:
	if not attack_slot_claimed:
		return
	if manager != null and manager.has_method("on_tentacle_attack_finished"):
		manager.call("on_tentacle_attack_finished", self)


func _can_continue_corner_attack() -> bool:
	return is_inside_tree() and _active and not _dead and visible


func _attack_once() -> void:
	if attack_visual == null:
		return
	_hit_targets.clear()
	_show_attack_warning()

	await get_tree().create_timer(attack_warning_time).timeout
	if _dead or not _active or not visible:
		_hide_attack_visual()
		return

	_activate_attack_visual()
	_set_attack_enabled(true)
	await get_tree().physics_frame
	_damage_current_overlaps()
	await get_tree().create_timer(attack_active_time).timeout
	_set_attack_enabled(false)
	_hide_attack_visual()


func _top_visibility_loop() -> void:
	while is_inside_tree():
		if _dead or not _active:
			await get_tree().create_timer(0.5).timeout
			continue
		visible = true
		monitorable = true
		monitoring = true
		await get_tree().create_timer(top_visible_time).timeout
		if _dead:
			continue
		_set_attack_enabled(false)
		visible = false
		monitorable = false
		monitoring = false
		await get_tree().create_timer(randf_range(top_hidden_time_min, top_hidden_time_max)).timeout


func _start_timed_cycle() -> void:
	var cycle_token := _cycle_version
	call_deferred("_timed_cycle_loop", cycle_token)


func _timed_cycle_loop(cycle_token: int) -> void:
	while is_inside_tree():
		if cycle_token != _cycle_version or _dead:
			return
		if not _active:
			_set_body_visible(false)
			await get_tree().create_timer(0.5).timeout
			continue

		_set_body_visible(false)
		await get_tree().create_timer(timed_cycle_hidden_time).timeout
		if cycle_token != _cycle_version or _dead:
			return
		if not _active:
			continue

		while not _can_show_timed_cycle_body():
			await get_tree().create_timer(0.2).timeout
			if cycle_token != _cycle_version or _dead:
				return
			if not _active:
				break
		if not _active:
			continue

		if timed_cycle_spawn_warning_time > 0.0:
			_show_spawn_warning()
			await get_tree().create_timer(timed_cycle_spawn_warning_time).timeout
			_hide_spawn_warning()
			if cycle_token != _cycle_version or _dead:
				return
			if not _active:
				continue

		_set_body_visible(true)
		await get_tree().create_timer(timed_cycle_idle_time).timeout
		if cycle_token != _cycle_version or _dead:
			return
		if timed_cycle_attack_before_hide and _active and visible:
			if corner_attack_visual != null:
				await _corner_attack_once()
			else:
				await _attack_once()
			if cycle_token != _cycle_version or _dead:
				return

		_set_attack_enabled(false)
		_hide_attack_visual()
		_hide_corner_attack_visual()
		_set_body_visible(false)
		await get_tree().create_timer(timed_cycle_hidden_time).timeout


func _set_attack_enabled(enabled: bool) -> void:
	if attack_area != null:
		attack_area.set_deferred("monitoring", enabled)
	if not attack_frame_hitboxes.is_empty():
		if enabled:
			_disable_attack_frame_hitboxes()
		else:
			_disable_attack_frame_hitboxes()
	elif attack_shape != null:
		attack_shape.set_deferred("disabled", not enabled)


func _collect_attack_frame_hitboxes() -> void:
	attack_frame_hitboxes.clear()
	if attack_area == null:
		return
	for frame_number in range(1, 16):
		var hitbox := attack_area.get_node_or_null("HitboxFrame%d" % frame_number)
		if hitbox == null:
			continue
		attack_frame_hitboxes.append(hitbox)


func _disable_attack_frame_hitboxes() -> void:
	for hitbox in attack_frame_hitboxes:
		hitbox.set_deferred("disabled", true)


func _set_attack_frame_hitbox(frame_number: int) -> void:
	if attack_frame_hitboxes.is_empty():
		return
	for i in range(attack_frame_hitboxes.size()):
		var hitbox := attack_frame_hitboxes[i]
		hitbox.set_deferred("disabled", i != frame_number - 1)


func _set_body_visible(body_visible: bool) -> void:
	_spawn_warning_active = false
	visible = body_visible
	monitorable = body_visible
	monitoring = body_visible
	_set_idle_hitboxes_enabled(body_visible)
	if body_visible:
		call_deferred("_damage_current_touch_overlaps")


func _show_spawn_warning() -> void:
	_spawn_warning_active = true
	visible = true
	monitorable = false
	monitoring = false
	if visual != null:
		visual.visible = true
		visual.modulate = spawn_warning_color
	if corner_attack_visual != null:
		corner_attack_visual.visible = false
	if fan_warning_visual != null:
		fan_warning_visual.visible = false
	_set_attack_enabled(false)


func _hide_spawn_warning() -> void:
	_spawn_warning_active = false
	if visual != null:
		visual.modulate = Color.WHITE
	visible = false
	monitorable = false
	monitoring = false
	_set_idle_hitboxes_enabled(false)


func _can_show_timed_cycle_body() -> bool:
	if max_visible_timed_cycle_siblings <= 0:
		return true
	var parent_node := get_parent()
	if parent_node == null:
		return true

	var visible_count := 0
	for sibling in parent_node.get_children():
		if sibling == self:
			continue
		if not sibling is Node:
			continue
		if bool(sibling.get("timed_cycle_enabled")) and bool(sibling.get("visible")):
			visible_count += 1

	return visible_count < max_visible_timed_cycle_siblings


func _collect_idle_frame_hitboxes() -> void:
	idle_frame_hitboxes.clear()
	for frame_number in range(1, 16):
		var hitbox := get_node_or_null("IdleHitboxFrame%d" % frame_number)
		if hitbox == null:
			continue
		idle_frame_hitboxes.append(hitbox)
	if not idle_frame_hitboxes.is_empty() and idle_base_shape != null:
		idle_base_shape.disabled = true


func _set_idle_hitboxes_enabled(enabled: bool) -> void:
	if idle_frame_hitboxes.is_empty():
		if idle_base_shape != null:
			idle_base_shape.set_deferred("disabled", not enabled)
		return
	for hitbox in idle_frame_hitboxes:
		hitbox.set_deferred("disabled", true)
	if enabled:
		_last_idle_hitbox_frame = -1
		_update_idle_frame_hitbox()


func _update_idle_frame_hitbox() -> void:
	if idle_frame_hitboxes.is_empty():
		return
	if not visible or not monitorable or _dead or _spawn_warning_active:
		for hitbox in idle_frame_hitboxes:
			hitbox.set_deferred("disabled", true)
		return
	if not (visual is AnimatedSprite2D):
		return
	var idle_sprite := visual as AnimatedSprite2D
	var frame_number := idle_sprite.frame + 1
	if frame_number == _last_idle_hitbox_frame:
		return
	_last_idle_hitbox_frame = frame_number
	for i in range(idle_frame_hitboxes.size()):
		var hitbox := idle_frame_hitboxes[i]
		hitbox.set_deferred("disabled", i != frame_number - 1)


func _on_attack_area_entered(area: Area2D) -> void:
	if _dead or not _active:
		return
	_damage_target(area)


func _on_attack_body_entered(body: Node2D) -> void:
	if _dead or not _active:
		return
	_damage_target(body)


func _on_touch_area_entered(area: Area2D) -> void:
	if _dead or not _active or _spawn_warning_active:
		return
	_damage_touch_target(area)


func _on_touch_area_exited(area: Area2D) -> void:
	_clear_touch_target(area)


func _on_touch_body_entered(body: Node2D) -> void:
	if _dead or not _active or _spawn_warning_active:
		return
	_damage_touch_target(body)


func _on_touch_body_exited(body: Node2D) -> void:
	_clear_touch_target(body)


func _damage_current_touch_overlaps() -> void:
	if _dead or not _active or not visible or _spawn_warning_active:
		return
	for area in get_overlapping_areas():
		_damage_touch_target(area)
	for body in get_overlapping_bodies():
		_damage_touch_target(body)


func _damage_touch_target(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null:
		return
	var instance_id := int(receiver.get_instance_id())
	if _touch_targets.has(instance_id):
		return
	_touch_targets[instance_id] = true
	receiver.call("take_damage", touch_damage, global_position)


func _clear_touch_target(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null:
		return
	_touch_targets.erase(int(receiver.get_instance_id()))


func _damage_current_overlaps() -> void:
	if attack_area == null:
		return
	for area in attack_area.get_overlapping_areas():
		_damage_target(area)
	for body in attack_area.get_overlapping_bodies():
		_damage_target(body)


func _damage_target(target: Node) -> void:
	var receiver := _find_damage_receiver(target)
	if receiver == null:
		return
	var instance_id := int(receiver.get_instance_id())
	if _hit_targets.has(instance_id):
		return
	_hit_targets[instance_id] = true
	receiver.call("take_damage", damage, global_position)


func _find_damage_receiver(target: Node) -> Node:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null


func _flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	visual.modulate = Color.WHITE * 2.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _get_attack_collision_node() -> Node:
	var shape := get_node_or_null("AttackArea/CollisionShape2D")
	if shape != null:
		return shape
	return get_node_or_null("AttackArea/CollisionPolygon2D")


func _show_attack_warning() -> void:
	if show_fan_warning and fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = warning_color
	if attack_visual == null:
		return
	attack_visual.visible = true
	attack_visual.modulate = warning_color if attack_visual_tint else Color.WHITE
	if attack_visual is AnimatedSprite2D:
		var warning_sprite := attack_visual as AnimatedSprite2D
		warning_sprite.stop()
		warning_sprite.frame = 0


func _activate_attack_visual() -> void:
	if show_fan_warning and fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = active_color
	if attack_visual == null:
		return
	attack_visual.modulate = active_color if attack_visual_tint else Color.WHITE
	if attack_visual is AnimatedSprite2D:
		var active_sprite := attack_visual as AnimatedSprite2D
		active_sprite.frame = 0
		active_sprite.play("attack")


func _hide_attack_visual() -> void:
	if fan_warning_visual != null:
		fan_warning_visual.visible = false
	if attack_visual == null:
		return
	if attack_visual is AnimatedSprite2D:
		var hidden_sprite := attack_visual as AnimatedSprite2D
		hidden_sprite.stop()
	attack_visual.visible = false


func _align_attack_visual() -> void:
	if not align_attack_visual_to_visual:
		return
	if visual == null or attack_visual == null:
		return
	if visual is Node2D and attack_visual is Node2D:
		var visual_node := visual as Node2D
		var attack_node := attack_visual as Node2D
		attack_node.position = visual_node.position
		attack_node.rotation = visual_node.rotation
		attack_node.scale = visual_node.scale


func _corner_attack_once() -> void:
	if corner_attack_visual == null:
		return
	var attack_slot_claimed := await _wait_for_tentacle_attack_slot()
	if not attack_slot_claimed:
		return
	_align_corner_attack_visual()
	if visual != null:
		visual.visible = true
		visual.modulate = Color(1.0, 0.22, 0.22)
	_hit_targets.clear()
	if show_fan_warning and fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = warning_color
	var warning_elapsed := await _play_corner_prep_animation()
	var remaining_warning: float = maxf(0.0, attack_warning_time - warning_elapsed)
	if remaining_warning > 0.0:
		await get_tree().create_timer(remaining_warning).timeout
	if not _can_continue_corner_attack():
		_hide_corner_attack_visual()
		_notify_tentacle_attack_finished(attack_slot_claimed)
		return
	if visual != null:
		visual.visible = false
		visual.modulate = Color.WHITE
	if show_fan_warning and fan_warning_visual != null:
		fan_warning_visual.visible = true
		fan_warning_visual.modulate = active_color
	corner_attack_visual.visible = true
	corner_attack_visual.modulate = Color.WHITE
	if corner_attack_visual is AnimatedSprite2D:
		var corner_sprite := corner_attack_visual as AnimatedSprite2D
		corner_sprite.stop()
		corner_sprite.frame = 0
		corner_sprite.play("attack")
		if attack_frame_hitboxes.is_empty():
			_set_attack_enabled(true)
			await get_tree().physics_frame
			_damage_current_overlaps()
			await get_tree().create_timer(attack_active_time).timeout
			_set_attack_enabled(false)
		else:
			await _run_corner_attack_frame_hitboxes(corner_sprite)
	else:
		_set_attack_enabled(true)
		await get_tree().physics_frame
		_damage_current_overlaps()
		await get_tree().create_timer(attack_active_time).timeout
		_set_attack_enabled(false)
	_hide_corner_attack_visual()
	_notify_tentacle_attack_finished(attack_slot_claimed)


func _run_corner_attack_frame_hitboxes(corner_sprite: AnimatedSprite2D) -> void:
	_set_attack_enabled(true)
	var elapsed := 0.0
	var last_frame := -1
	while elapsed < attack_active_time and _can_continue_corner_attack():
		var frame_number := corner_sprite.frame + 1
		if frame_number != last_frame:
			_set_attack_frame_hitbox(frame_number)
			await get_tree().physics_frame
			_damage_current_overlaps()
			last_frame = frame_number
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	_set_attack_enabled(false)


func _play_corner_prep_animation() -> float:
	if not corner_prep_enabled or not (visual is AnimatedSprite2D):
		return 0.0

	var elapsed := 0.0
	var random_delay := randf_range(corner_prep_random_delay_min, corner_prep_random_delay_max)
	if random_delay > 0.0:
		await get_tree().create_timer(random_delay).timeout
		elapsed += random_delay
		if not _can_continue_corner_attack():
			return elapsed

	var idle_sprite := visual as AnimatedSprite2D
	var idle_animation := _get_corner_idle_animation(idle_sprite)
	var frame_count := _get_corner_idle_frame_count(idle_sprite, idle_animation)
	if frame_count <= 0:
		return elapsed

	var prep_frame_time := corner_prep_frame_time
	if idle_sprite.sprite_frames != null and idle_sprite.sprite_frames.has_animation(idle_animation):
		var idle_fps := idle_sprite.sprite_frames.get_animation_speed(idle_animation)
		if idle_fps > 0.0:
			prep_frame_time = 1.0 / idle_fps

	idle_sprite.visible = true
	idle_sprite.stop()
	idle_sprite.animation = idle_animation

	var sequence := _pick_corner_prep_sequence()
	var last_frame_number := -1
	for frame_number in sequence:
		if not _can_continue_corner_attack():
			return elapsed
		_set_corner_idle_frame(idle_sprite, frame_number, frame_count)
		last_frame_number = frame_number
		await get_tree().create_timer(prep_frame_time).timeout
		elapsed += prep_frame_time

	if last_frame_number != corner_prep_attack_link_frame:
		if not _can_continue_corner_attack():
			return elapsed
		_set_corner_idle_frame(idle_sprite, corner_prep_attack_link_frame, frame_count)
		await get_tree().create_timer(prep_frame_time).timeout
		elapsed += prep_frame_time

	return elapsed


func _pick_corner_prep_sequence() -> Array:
	var sequence_count := CORNER_PREP_SEQUENCES.size()
	if sequence_count <= 0:
		return [corner_prep_attack_link_frame]

	var sequence_index := corner_prep_sequence_index
	if sequence_index < 0 or sequence_index >= sequence_count:
		sequence_index = randi() % sequence_count
	return CORNER_PREP_SEQUENCES[sequence_index]


func _get_corner_idle_animation(idle_sprite: AnimatedSprite2D) -> StringName:
	if idle_sprite.sprite_frames != null and idle_sprite.sprite_frames.has_animation(&"idle"):
		return &"idle"
	return idle_sprite.animation


func _get_corner_idle_frame_count(idle_sprite: AnimatedSprite2D, animation_name: StringName) -> int:
	if idle_sprite.sprite_frames == null:
		return 0
	if not idle_sprite.sprite_frames.has_animation(animation_name):
		return 0
	return idle_sprite.sprite_frames.get_frame_count(animation_name)


func _set_corner_idle_frame(idle_sprite: AnimatedSprite2D, frame_number: int, frame_count: int) -> void:
	var zero_based_frame: int = clampi(frame_number - 1, 0, frame_count - 1)
	idle_sprite.frame = zero_based_frame


func _resume_corner_idle_visual() -> void:
	if not (visual is AnimatedSprite2D):
		return
	var idle_sprite := visual as AnimatedSprite2D
	var idle_animation := _get_corner_idle_animation(idle_sprite)
	if idle_sprite.sprite_frames != null and idle_sprite.sprite_frames.has_animation(idle_animation):
		idle_sprite.animation = idle_animation
		idle_sprite.play()


func _hide_corner_attack_visual() -> void:
	if corner_attack_visual != null:
		if corner_attack_visual is AnimatedSprite2D:
			var corner_sprite := corner_attack_visual as AnimatedSprite2D
			corner_sprite.stop()
		corner_attack_visual.visible = false
	if fan_warning_visual != null:
		fan_warning_visual.visible = false
	if visual != null and visible and not _dead:
		visual.visible = true
		visual.modulate = Color.WHITE
		_resume_corner_idle_visual()



func _align_corner_attack_visual() -> void:
	if not align_attack_visual_to_visual:
		return
	if visual == null or corner_attack_visual == null:
		return
	if visual is Node2D and corner_attack_visual is Node2D:
		var visual_node := visual as Node2D
		var corner_node := corner_attack_visual as Node2D
		corner_node.position = visual_node.position
		corner_node.rotation = visual_node.rotation
