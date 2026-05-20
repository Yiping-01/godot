extends Node2D

signal defeated

const OCTOPUS_TEXTURE := preload("res://demo/assets/boss/octopus_boss.png")

@export var max_health := 6

var health := max_health
var hurtbox: Area2D
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("enemy")
	if get_node_or_null("Sprite2D") == null:
		_build_nodes()
	else:
		sprite = get_node("Sprite2D") as Sprite2D
		hurtbox = get_node_or_null("Hurtbox") as Area2D
	set_process(false)


func wake() -> void:
	health = max_health
	set_process(true)


func _build_nodes() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = OCTOPUS_TEXTURE
	sprite.scale = Vector2(0.82, 0.82)
	sprite.modulate = Color(0.8, 1.0, 1.0, 0.92)
	sprite.z_index = 13
	add_child(sprite)

	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 8
	add_child(hurtbox)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(250, 170)
	shape.shape = rect
	hurtbox.add_child(shape)


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.8, 1.0, 1.0, 0.92), 0.18)
	if health <= 0:
		defeated.emit()
		queue_free()
