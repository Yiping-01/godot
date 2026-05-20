extends StaticBody2D

signal destroyed(wire: Node)

@export var max_health := 2

var health := max_health
var active := false

@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")
@onready var debug_body: CanvasItem = get_node_or_null("DebugBody")
@onready var telegraph: CanvasItem = get_node_or_null("Telegraph")


func _ready() -> void:
	add_to_group("enemy")
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	visible = false
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true


func wake() -> void:
	if active:
		return
	active = true
	health = max_health
	visible = true
	collision_layer = 1
	collision_mask = 2
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
		for child in hurtbox.get_children():
			if child is CollisionShape2D:
				child.disabled = false
	modulate.a = 0.0
	scale.y = 0.12
	if telegraph != null:
		telegraph.visible = true
		telegraph.modulate.a = 0.72
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.32)
	tween.tween_property(self, "scale:y", 1.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	if telegraph != null:
		telegraph.visible = false


func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if not active:
		return
	health -= amount
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color(0.65, 0.98, 1.0, 1.0), 0.12)
	if health <= 0:
		destroyed.emit(self)
		_break()


func _break() -> void:
	active = false
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale:y", 0.05, 0.22)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
