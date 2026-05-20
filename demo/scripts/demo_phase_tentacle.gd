extends Node2D

signal defeated(tentacle: Node)

@export var max_health := 4
@export var attack_side := 1
@export var attack_cooldown := 2.1
@export var attack_range := Vector2(520, 260)
@export var player_path: NodePath

var health := max_health
var player: Node2D
var active := false
var attacking := false
var cooldown := 0.0

@onready var sprite: CanvasItem = get_node_or_null("Sprite2D")
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var attack_shape: CollisionShape2D = get_node_or_null("AttackArea/CollisionShape2D")
@onready var debug_attack: CanvasItem = get_node_or_null("DebugAttackRange")
@onready var telegraph: CanvasItem = get_node_or_null("Telegraph")


func _ready() -> void:
	add_to_group("enemy")
	player = get_node_or_null(player_path) as Node2D
	if attack_area != null:
		attack_area.body_entered.connect(_on_attack_body_entered)
		attack_area.area_entered.connect(_on_attack_area_entered)
	if sprite is AnimatedSprite2D:
		(sprite as AnimatedSprite2D).play(&"walk")
	_set_attack_enabled(false)
	_set_hurtbox_enabled(false)
	visible = false
	set_physics_process(false)


func wake() -> void:
	if active:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	active = true
	health = max_health
	visible = true
	scale = Vector2(0.15, 0.15)
	modulate.a = 0.0
	_set_hurtbox_enabled(true)
	set_physics_process(true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.36)


func sleep() -> void:
	active = false
	visible = false
	set_physics_process(false)
	_set_attack_enabled(false)
	_set_hurtbox_enabled(false)


func _physics_process(delta: float) -> void:
	if not active or attacking or player == null:
		return
	cooldown -= delta
	var to_player := player.global_position - global_position
	if cooldown <= 0.0 and absf(to_player.x) <= attack_range.x and absf(to_player.y) <= attack_range.y:
		_attack(1 if to_player.x >= 0.0 else -1)


func _attack(direction: int) -> void:
	attacking = true
	cooldown = attack_cooldown
	var dir := 1 if direction >= 0 else -1
	if sprite is AnimatedSprite2D:
		var animated := sprite as AnimatedSprite2D
		animated.flip_h = dir < 0
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(&"attack"):
			animated.play(&"attack")
	if telegraph != null:
		telegraph.visible = true
		telegraph.scale.x = absf(telegraph.scale.x) * dir
		telegraph.modulate.a = 0.0
		var warning := create_tween()
		warning.tween_property(telegraph, "modulate:a", 0.78, 0.2)
		warning.tween_property(telegraph, "modulate:a", 0.18, 0.16)
		warning.tween_property(telegraph, "modulate:a", 0.78, 0.14)
	await get_tree().create_timer(0.46).timeout
	if not is_instance_valid(self) or not active:
		return
	_set_attack_enabled(true)
	if attack_area != null:
		attack_area.position.x = absf(attack_area.position.x) * dir
	if debug_attack != null:
		debug_attack.visible = true
		debug_attack.scale.x = absf(debug_attack.scale.x) * dir
	await get_tree().create_timer(0.32).timeout
	_set_attack_enabled(false)
	if telegraph != null:
		telegraph.visible = false
	if debug_attack != null:
		debug_attack.visible = true
	if sprite is AnimatedSprite2D:
		var animated := sprite as AnimatedSprite2D
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(&"walk"):
			animated.play(&"walk")
	attacking = false


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if not active:
		return
	health -= amount
	var dir := signf(global_position.x - from_position.x)
	position.x += dir * 8.0
	if sprite != null:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(0.62, 0.98, 1.0, 0.92), 0.16)
	if health <= 0:
		active = false
		_set_attack_enabled(false)
		_set_hurtbox_enabled(false)
		defeated.emit(self)
		var sink := create_tween()
		sink.set_parallel(true)
		sink.tween_property(self, "position:y", position.y + 90.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		sink.tween_property(self, "modulate:a", 0.0, 0.26)
		await sink.finished
		visible = false


func _set_hurtbox_enabled(enabled: bool) -> void:
	if hurtbox == null:
		return
	hurtbox.monitorable = enabled
	hurtbox.monitoring = enabled
	for child in hurtbox.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled


func _set_attack_enabled(enabled: bool) -> void:
	if attack_area != null:
		attack_area.monitoring = enabled
		attack_area.monitorable = enabled
	if attack_shape != null:
		attack_shape.disabled = not enabled


func _on_attack_body_entered(body: Node) -> void:
	_damage_player(body)


func _on_attack_area_entered(area: Area2D) -> void:
	_damage_player(area)


func _damage_player(target: Node) -> void:
	var current := target
	while current != null:
		if current.has_method("take_damage"):
			current.call("take_damage", 1, global_position)
			return
		current = current.get_parent()
