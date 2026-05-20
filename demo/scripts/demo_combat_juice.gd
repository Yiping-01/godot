extends Node
class_name DemoCombatJuice

const DEMO_SCENE_PREFIX := "res://demo/"
const FLASH_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/flash_round.png"
const BURST_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/explode_particle.png"
const SMOKE_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/orange_puff_animated.png"
const SPARK_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/white_hit_particle.png"
const DONUT_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/white_light_donut.png"

static var _hit_pause_active := false


static func is_enabled(context: Node) -> bool:
	if context == null or not context.is_inside_tree():
		return false

	var scene := context.get_tree().current_scene
	return scene != null and scene.scene_file_path.begins_with(DEMO_SCENE_PREFIX)


static func play_hit_pause(context: Node, duration := 0.055, time_scale := 0.08) -> void:
	if not is_enabled(context) or _hit_pause_active:
		return

	_hit_pause_active = true
	var previous_scale := Engine.time_scale
	Engine.time_scale = clampf(time_scale, 0.01, 1.0)
	var timer := context.get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = previous_scale
		_hit_pause_active = false
	)


static func spawn_hit_flash(context: Node, position: Vector2, direction := 1) -> void:
	if not is_enabled(context):
		return

	var root := _effect_root(context)
	if root == null:
		return

	var flash_texture := load(FLASH_TEXTURE_PATH)
	if flash_texture == null:
		return

	var flash := Sprite2D.new()
	flash.name = "DemoHitFlash"
	flash.texture = flash_texture
	flash.global_position = position
	flash.rotation = -0.35 * float(direction)
	flash.scale = Vector2(0.18, 0.42)
	flash.z_index = 350
	flash.modulate = Color(1.0, 1.0, 1.0, 0.86)
	root.add_child(flash)

	var slash := Line2D.new()
	slash.name = "DemoSlashTrace"
	slash.width = 7.0
	slash.default_color = Color(0.84, 0.96, 1.0, 0.9)
	slash.z_index = 351
	slash.global_position = position
	slash.rotation = -0.4 * float(direction)
	slash.add_point(Vector2(-42.0, 0.0))
	slash.add_point(Vector2(0.0, -10.0))
	slash.add_point(Vector2(46.0, 1.0))
	root.add_child(slash)

	var flash_tween := flash.create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", flash.scale * 1.7, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.12)
	flash_tween.chain().tween_callback(Callable(flash, "queue_free"))

	var slash_tween := slash.create_tween()
	slash_tween.tween_property(slash, "modulate:a", 0.0, 0.14)
	slash_tween.tween_callback(Callable(slash, "queue_free"))


static func spawn_death_burst(context: Node, position: Vector2, scale_multiplier := 1.0) -> void:
	if not is_enabled(context):
		return

	var root := _effect_root(context)
	if root == null:
		return

	var burst_texture := load(BURST_TEXTURE_PATH)
	var smoke_texture := load(SMOKE_TEXTURE_PATH)
	var spark_texture := load(SPARK_TEXTURE_PATH)
	_spawn_particle_burst(root, position, burst_texture, 24, 0.42, 110.0 * scale_multiplier, Color(1.0, 0.86, 0.45, 0.82))
	_spawn_particle_burst(root, position + Vector2(0.0, -8.0), smoke_texture, 14, 0.54, 64.0 * scale_multiplier, Color(1.0, 0.42, 0.14, 0.42))
	_spawn_particle_burst(root, position + Vector2(0.0, -14.0), spark_texture, 16, 0.32, 140.0 * scale_multiplier, Color(0.85, 1.0, 1.0, 0.72))
	_spawn_death_light(root, position, scale_multiplier)

	var shock_texture := load(DONUT_TEXTURE_PATH)
	if shock_texture == null:
		return

	var shock := Sprite2D.new()
	shock.name = "DemoDeathShock"
	shock.texture = shock_texture
	shock.global_position = position
	shock.scale = Vector2.ONE * 0.055 * scale_multiplier
	shock.z_index = 330
	shock.modulate = Color(0.9, 1.0, 1.0, 0.78)
	root.add_child(shock)

	var tween := shock.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shock, "scale", Vector2.ONE * 0.46 * scale_multiplier, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shock, "modulate:a", 0.0, 0.32)
	tween.chain().tween_callback(Callable(shock, "queue_free"))


static func spawn_boss_death_sequence(context: Node, position: Vector2, scale_multiplier := 1.0) -> void:
	if not is_enabled(context):
		return

	var root := _effect_root(context)
	if root == null:
		return

	play_hit_pause(context, 0.34, 0.12)
	_spawn_boss_flash(root, position, scale_multiplier)
	_spawn_boss_shock_lines(root, position, scale_multiplier)
	_spawn_boss_death_particles(root, position, scale_multiplier)
	_spawn_death_light(root, position, scale_multiplier * 2.5)

	for step in range(4):
		var step_scale := scale_multiplier * (0.75 + float(step) * 0.16)
		var timer := root.get_tree().create_timer(0.16 + float(step) * 0.13, true, false, true)
		timer.timeout.connect(func() -> void:
			var burst_pos := position + Vector2(randf_range(-90.0, 90.0), randf_range(-80.0, 50.0))
			_spawn_boss_death_particles(root, burst_pos, step_scale)
			_spawn_boss_flash(root, burst_pos, scale_multiplier * 0.55)
		)


static func shake_camera(context: Node, duration := 0.18, strength := 5.0) -> void:
	if not is_enabled(context):
		return

	var receiver: Node = context
	if not receiver.has_method("_start_camera_shake"):
		receiver = context.get_tree().get_first_node_in_group("player")

	if receiver != null and receiver.has_method("_start_camera_shake"):
		receiver.call("_start_camera_shake", duration, strength)


static func spawn_intro_ring(context: Node, position: Vector2, radius := 92.0, color := Color(0.78, 0.94, 1.0, 0.75)) -> void:
	if not is_enabled(context):
		return

	var root := _effect_root(context)
	if root == null:
		return

	var ring := Line2D.new()
	ring.name = "DemoIntroRing"
	ring.closed = true
	ring.width = 9.0
	ring.default_color = color
	ring.z_index = 340
	ring.global_position = position
	for point in _circle_points(radius, 56):
		ring.add_point(point)
	root.add_child(ring)

	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * 5.4, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(Callable(ring, "queue_free"))


static func _spawn_particle_burst(root: Node, position: Vector2, texture: Texture2D, amount: int, lifetime: float, velocity: float, color: Color) -> void:
	if texture == null:
		return

	var particles := CPUParticles2D.new()
	particles.name = "DemoBurstParticles"
	particles.global_position = position
	particles.z_index = 325
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.78
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, 220.0)
	particles.initial_velocity_min = velocity * 0.35
	particles.initial_velocity_max = velocity
	particles.scale_amount_min = 0.012
	particles.scale_amount_max = 0.062
	particles.color = color
	particles.texture = texture
	root.add_child(particles)
	particles.emitting = true

	var timer := root.get_tree().create_timer(lifetime + 0.18, true, false, true)
	timer.timeout.connect(Callable(particles, "queue_free"))


static func _spawn_boss_death_particles(root: Node, position: Vector2, scale_multiplier: float) -> void:
	var burst_texture := load(BURST_TEXTURE_PATH)
	var smoke_texture := load(SMOKE_TEXTURE_PATH)
	var spark_texture := load(SPARK_TEXTURE_PATH)
	_spawn_particle_burst(root, position + Vector2(0.0, -38.0), burst_texture, 130, 1.1, 470.0 * scale_multiplier, Color(1.0, 0.78, 0.12, 0.96))
	_spawn_particle_burst(root, position + Vector2(0.0, -12.0), smoke_texture, 42, 1.35, 235.0 * scale_multiplier, Color(1.0, 0.36, 0.08, 0.45))
	_spawn_particle_burst(root, position + Vector2(0.0, -54.0), spark_texture, 64, 0.82, 540.0 * scale_multiplier, Color(1.0, 0.98, 0.78, 0.95))


static func _spawn_boss_flash(root: Node, position: Vector2, scale_multiplier: float) -> void:
	var flash_texture := load(FLASH_TEXTURE_PATH)
	if flash_texture == null:
		return
	var flash := Sprite2D.new()
	flash.name = "DemoBossDeathFlash"
	flash.texture = flash_texture
	flash.global_position = position + Vector2(0.0, -36.0)
	flash.z_index = 390
	flash.scale = Vector2.ONE * 0.2 * scale_multiplier
	flash.modulate = Color(1.0, 0.92, 0.52, 0.95)
	root.add_child(flash)
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2.ONE * 2.1 * scale_multiplier, 0.42).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.42)
	tween.chain().tween_callback(Callable(flash, "queue_free"))


static func _spawn_boss_shock_lines(root: Node, position: Vector2, scale_multiplier: float) -> void:
	for i in range(18):
		var angle := TAU * float(i) / 18.0 + randf_range(-0.08, 0.08)
		var length := randf_range(260.0, 680.0) * scale_multiplier
		var line := Line2D.new()
		line.name = "DemoBossDeathLine"
		line.width = randf_range(5.0, 10.0)
		line.default_color = Color(1.0, 0.96, 0.72, 0.92)
		line.z_index = 385
		line.global_position = position + Vector2(0.0, -42.0)
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2(cos(angle), sin(angle)) * length)
		root.add_child(line)
		var tween := line.create_tween()
		tween.set_parallel(true)
		tween.tween_property(line, "modulate:a", 0.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(line, "width", 1.0, 0.36)
		tween.chain().tween_callback(Callable(line, "queue_free"))


static func _spawn_death_light(root: Node, position: Vector2, scale_multiplier: float) -> void:
	var texture := load(FLASH_TEXTURE_PATH)
	if texture == null:
		return
	var light := PointLight2D.new()
	light.name = "DemoDeathLight"
	light.texture = texture
	light.global_position = position
	light.energy = 1.1
	light.texture_scale = 0.65 * scale_multiplier
	light.color = Color(1.0, 0.62, 0.32, 1.0)
	light.z_index = 326
	root.add_child(light)
	var tween := light.create_tween()
	tween.set_parallel(true)
	tween.tween_property(light, "energy", 0.0, 0.28)
	tween.tween_property(light, "texture_scale", 1.3 * scale_multiplier, 0.28)
	tween.chain().tween_callback(Callable(light, "queue_free"))


static func _effect_root(context: Node) -> Node:
	var scene := context.get_tree().current_scene
	if scene != null:
		return scene
	return context.get_parent()


static func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points
