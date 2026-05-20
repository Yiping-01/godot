extends Node2D

signal defeated(tentacle: Node)

@export var max_health := 3
@export var attack_side := 1
@export var attack_cooldown := 1.85
@export var player_path: NodePath

var health := max_health
var player: Node2D
var cooldown := 0.6
var attacking := false
var hurtbox: Area2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var body_line: Line2D
var attack_line: Line2D


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_build_nodes()
	player = get_node_or_null(player_path) as Node2D
	set_physics_process(false)


func wake() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if attacking:
		return
	cooldown -= delta
	if cooldown > 0.0 or player == null:
		return
	var to_player := player.global_position - global_position
	if absf(to_player.x) <= 520.0 and absf(to_player.y) <= 230.0:
		_attack(1 if to_player.x >= 0.0 else -1)


func _build_nodes() -> void:
	body_line = Line2D.new()
	body_line.name = "TentacleBody"
	body_line.width = 28.0
	body_line.default_color = Color(0.38, 0.88, 0.95, 0.74)
	body_line.points = PackedVector2Array([Vector2(0, 110), Vector2(18 * attack_side, 48), Vector2(0, 0), Vector2(55 * attack_side, -58)])
	body_line.z_index = 8
	add_child(body_line)

	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 8
	add_child(hurtbox)
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(92, 190)
	hurt_shape.shape = hurt_rect
	hurtbox.add_child(hurt_shape)

	attack_line = Line2D.new()
	attack_line.name = "AttackTrace"
	attack_line.width = 22.0
	attack_line.default_color = Color(0.74, 1.0, 0.98, 0.0)
	attack_line.z_index = 12
	add_child(attack_line)

	attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 32
	attack_area.collision_mask = 16
	attack_area.monitoring = false
	attack_area.monitorable = false
	add_child(attack_area)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_area.area_entered.connect(_on_attack_area_entered)

	attack_shape = CollisionShape2D.new()
	var attack_rect := RectangleShape2D.new()
	attack_rect.size = Vector2(310, 76)
	attack_shape.shape = attack_rect
	attack_shape.disabled = true
	attack_area.add_child(attack_shape)


func _attack(direction: int) -> void:
	attacking = true
	cooldown = attack_cooldown
	var dir := 1 if direction >= 0 else -1
	attack_area.position = Vector2(155 * dir, -18)
	attack_line.points = PackedVector2Array([Vector2(20 * dir, -20), Vector2(320 * dir, -34)])
	attack_shape.disabled = false
	attack_area.monitoring = true
	attack_area.monitorable = true
	var tween := create_tween()
	attack_line.modulate.a = 0.0
	tween.tween_property(attack_line, "modulate:a", 0.88, 0.08)
	tween.tween_property(attack_line, "modulate:a", 0.0, 0.22)
	await get_tree().create_timer(0.24).timeout
	attack_shape.disabled = true
	attack_area.monitoring = false
	attack_area.monitorable = false
	attacking = false


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	var knock_dir := signf(global_position.x - from_position.x)
	position.x += 9.0 * knock_dir
	body_line.default_color = Color(0.88, 1.0, 1.0, 0.95)
	var tween := create_tween()
	tween.tween_property(body_line, "default_color", Color(0.38, 0.88, 0.95, 0.74), 0.16)
	if health <= 0:
		defeated.emit(self)
		queue_free()


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
