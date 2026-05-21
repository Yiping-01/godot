extends Area2D

@export var damage_to_boss := 10
@export var fade_time := 0.35
@export var core_dark_color := Color(0.82, 0.15, 0.20, 1.0)
@export var core_hit_color := Color(1.0, 0.96, 0.86, 1.0)
@export var highlight_color := Color(1.0, 0.30, 0.34, 1.0)
@export var highlight_dim_color := Color(0.88, 0.12, 0.18, 1.0)
@export var light_energy_vulnerable := 0.68
@export var light_energy_dim := 0.18
@export var light_breathe_time := 0.78

const CORE_HIGHLIGHT_SHADER := preload("res://demo/shaders/boss_core_highlight.gdshader")

var manager: Node
var _open := false
var _vulnerable := false
var _flash_tween: Tween
var _glow_tween: Tween
var _fade_tween: Tween
var _light_tween: Tween
var _highlight_material: ShaderMaterial

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem
@onready var glow: CanvasItem = get_node_or_null("CoreGlow") as CanvasItem
@onready var core_light: PointLight2D = get_node_or_null("CoreLight") as PointLight2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	_setup_highlight_material()
	close_core()


func set_manager(new_manager: Node) -> void:
	manager = new_manager


func show_core() -> void:
	_open = true
	visible = true
	if visual != null:
		visual.visible = true
		visual.modulate = Color(core_dark_color.r, core_dark_color.g, core_dark_color.b, 0.0)
	if glow != null:
		glow.visible = true
		glow.modulate = Color(0.72, 0.08, 0.11, 0.0)
	if core_light != null:
		core_light.visible = true
		core_light.enabled = true
		core_light.color = Color(0.95, 0.12, 0.16, 1.0)
		core_light.energy = 0.0
	_set_highlight_alpha(0.0)
	set_vulnerable(true)

	_kill_fade_tween()
	_fade_tween = create_tween()
	if visual != null:
		_fade_tween.tween_property(visual, "modulate", core_dark_color, fade_time)
	if glow != null:
		_fade_tween.parallel().tween_property(glow, "modulate", Color(0.95, 0.12, 0.16, 0.34), fade_time)
	if core_light != null:
		_fade_tween.parallel().tween_property(core_light, "energy", light_energy_vulnerable, fade_time)
	_fade_tween.parallel().tween_method(Callable(self, "_set_highlight_alpha"), 0.0, 1.0, fade_time)
	_fade_tween.finished.connect(_on_show_core_fade_finished)


func hide_core() -> void:
	_open = false
	set_vulnerable(false)
	_kill_fade_tween()
	_stop_breathing_effects()
	_fade_tween = create_tween()
	if visual != null:
		_fade_tween.tween_property(visual, "modulate", Color(core_dark_color.r, core_dark_color.g, core_dark_color.b, 0.0), fade_time)
	if glow != null:
		_fade_tween.parallel().tween_property(glow, "modulate", Color(0.72, 0.08, 0.11, 0.0), fade_time)
	if core_light != null:
		_fade_tween.parallel().tween_property(core_light, "energy", 0.0, fade_time)
	_fade_tween.parallel().tween_method(Callable(self, "_set_highlight_alpha"), _get_highlight_alpha(), 0.0, fade_time)
	await _fade_tween.finished
	if not _open:
		visible = false
		if visual != null:
			visual.visible = false
		if glow != null:
			glow.visible = false
		if core_light != null:
			core_light.enabled = false
			core_light.visible = false


func set_vulnerable(enabled: bool) -> void:
	_vulnerable = enabled
	monitorable = enabled
	monitoring = enabled
	if collision_shape != null:
		collision_shape.disabled = not enabled
	if not enabled and core_light != null and _open:
		core_light.energy = light_energy_dim


func flash_hit() -> void:
	if visual == null:
		return
	if _flash_tween != null:
		_flash_tween.kill()
	_set_highlight_color(Color(1.0, 0.96, 0.86, 1.0))
	visual.modulate = core_hit_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", core_dark_color, 0.16)
	_flash_tween.parallel().tween_method(Callable(self, "_set_highlight_color"), Color(1.0, 0.96, 0.86, 1.0), highlight_color, 0.16)


func open_core() -> void:
	show_core()


func close_core() -> void:
	_open = false
	_stop_breathing_effects()
	_kill_fade_tween()
	set_vulnerable(false)
	visible = false
	if visual != null:
		visual.visible = false
		visual.modulate = Color(core_dark_color.r, core_dark_color.g, core_dark_color.b, 0.0)
	if glow != null:
		glow.visible = false
		glow.modulate = Color(0.72, 0.08, 0.11, 0.0)
	if core_light != null:
		core_light.energy = 0.0
		core_light.enabled = false
		core_light.visible = false
	_set_highlight_alpha(0.0)


func take_damage(_amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if not _open or not _vulnerable:
		return
	if manager != null and manager.has_method("damage_boss"):
		manager.call("damage_boss", damage_to_boss)
	flash_hit()


func _flash_hit() -> void:
	flash_hit()


func _start_glow() -> void:
	_start_breathing_effects()


func _stop_glow() -> void:
	_stop_breathing_effects()


func _on_show_core_fade_finished() -> void:
	if _open and _vulnerable:
		_start_breathing_effects()


func _setup_highlight_material() -> void:
	if visual == null:
		return
	_highlight_material = ShaderMaterial.new()
	_highlight_material.shader = CORE_HIGHLIGHT_SHADER
	_highlight_material.set_shader_parameter("base_color", Color(core_dark_color.r, core_dark_color.g, core_dark_color.b, 0.0))
	_highlight_material.set_shader_parameter("shine_color", Vector3(highlight_color.r, highlight_color.g, highlight_color.b))
	_highlight_material.set_shader_parameter("shine_alpha", 0.22)
	_highlight_material.set_shader_parameter("shine_angle", -35.0)
	_highlight_material.set_shader_parameter("shine_duration", 2.2)
	_highlight_material.set_shader_parameter("shine_speed", 170.0)
	_highlight_material.set_shader_parameter("shine_width", 18.0)
	visual.material = _highlight_material


func _start_breathing_effects() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.tween_method(Callable(self, "_set_highlight_alpha"), 0.72, 1.0, light_breathe_time)
	if glow != null:
		_glow_tween.parallel().tween_property(glow, "modulate", Color(1.0, 0.18, 0.22, 0.52), light_breathe_time)
	_glow_tween.tween_method(Callable(self, "_set_highlight_alpha"), 1.0, 0.72, light_breathe_time)
	if glow != null:
		_glow_tween.parallel().tween_property(glow, "modulate", Color(0.82, 0.10, 0.14, 0.30), light_breathe_time)

	if _glow_tween != null:
		_glow_tween.play()

	if _light_tween != null:
		_light_tween.kill()
	if core_light != null:
		_light_tween = create_tween()
		_light_tween.set_loops()
		_light_tween.tween_property(core_light, "energy", light_energy_vulnerable, light_breathe_time)
		_light_tween.tween_property(core_light, "energy", light_energy_dim, light_breathe_time)


func _stop_breathing_effects() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
	if _light_tween != null:
		_light_tween.kill()


func _kill_fade_tween() -> void:
	if _fade_tween != null:
		_fade_tween.kill()


func _set_highlight_alpha(alpha: float) -> void:
	if _highlight_material == null:
		return
	_highlight_material.set_shader_parameter("base_color", Color(core_dark_color.r, core_dark_color.g, core_dark_color.b, alpha))


func _get_highlight_alpha() -> float:
	if _highlight_material == null:
		return 0.0
	var color: Color = _highlight_material.get_shader_parameter("base_color")
	return color.a


func _set_highlight_color(color: Color) -> void:
	if _highlight_material == null:
		return
	_highlight_material.set_shader_parameter("shine_color", Vector3(color.r, color.g, color.b))

