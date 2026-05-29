extends Node2D
class_name DemoAtmosphere

@export var environment_tint := Color(0.25, 0.31, 0.36, 1.0)
@export_range(80.0, 760.0, 1.0) var player_glow_radius := 330.0
@export var level_width := 2400.0
@export var floor_y := 690.0
@export var artificial_sun_enabled := true
@export var artificial_sun_position := Vector2(420.0, 120.0)
@export var artificial_sun_color := Color(0.82, 0.95, 1.0, 1.0)
@export_range(0.0, 2.0, 0.01) var artificial_sun_energy := 0.46
@export_range(0.0, 1.0, 0.01) var artificial_sun_glow_alpha := 0.16

const GLOW_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/flash_round.png"
const BUBBLE_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/white_light_donut.png"
const WATER_TEXTURE_PATH := "res://demo/assets/hollow_import/effects/water_footstep_particle.png"
const DEFAULT_BG_TEXTURE_PATH := "res://demo/assets/art/backgrounds/parallax_bg_far.png"
const FLOOR_TEXTURE_PATH := "res://demo/assets/art/backgrounds/base_floor_single.png"
const PAINTED_FLOOR_TEXTURE_PATHS := [
	"res://demo/assets/tiles/floor_stone_tile_01.png",
	"res://demo/assets/tiles/floor_stone_tile_02.png",
	"res://demo/assets/tiles/floor_stone_tile_03.png",
	"res://demo/assets/tiles/floor_stone_tile_04.png",
]
const WALL_TEXTURE_PATH := "res://demo/assets/art/backgrounds/base_wall_single.png"
const CEILING_TEXTURE_PATH := "res://demo/assets/art/backgrounds/base_ceiling_single.png"
const PLANT_TEXTURE_PATH := "res://demo/assets/art/backgrounds/deepsea_prop_plant.png"

@export_file("*.png") var art_background_texture_path := DEFAULT_BG_TEXTURE_PATH
@export_file("*.png") var foreground_decor_texture_path := ""
@export_range(0.1, 1.2, 0.01) var foreground_decor_scale := 0.46
@export var foreground_decor_bottom_offset := 72.0
@export var underwater_bubbles_only := false

var player_glow: PointLight2D
var parallax_layers: Array[Node2D] = []
var air_motes: Array[Dictionary] = []
var atmosphere_time := 0.0


func _ready() -> void:
	z_index = -500
	_build_canvas_modulate()
	_remove_scene_backdrops()
	_build_environment_layers()
	call_deferred("_attach_player_glow")


func _process(delta: float) -> void:
	atmosphere_time += delta
	_attach_player_glow()
	_update_parallax()
	_update_air_motes()


func _build_canvas_modulate() -> void:
	var existing := get_node_or_null("DemoCanvasModulate") as CanvasModulate
	if existing != null:
		existing.color = environment_tint
		return

	var modulate_node := CanvasModulate.new()
	modulate_node.name = "DemoCanvasModulate"
	modulate_node.color = environment_tint
	add_child(modulate_node)


func _remove_scene_backdrops() -> void:
	var scene := get_parent()
	if scene != null:
		var background := scene.get_node_or_null("Background")
		if background != null:
			background.queue_free()

	for child in get_children():
		if child.name.begins_with("DemoFog") or child.name.begins_with("DemoAirMotes"):
			child.queue_free()


func _build_environment_layers() -> void:
	var root := get_node_or_null("DemoEnvironment")
	if root != null:
		root.queue_free()

	root = Node2D.new()
	root.name = "DemoEnvironment"
	root.z_index = -480
	add_child(root)
	parallax_layers.clear()
	air_motes.clear()

	_add_parallax_layer(root, "FarBackLayer", art_background_texture_path, 0.025, Vector2(0.0, floor_y - 330.0), Vector2(0.9, 0.9), Color(0.92, 1.0, 1.0, 0.68), -34)
	_add_parallax_layer(root, "FarFrontLayer", art_background_texture_path, 0.085, Vector2(420.0, floor_y - 315.0), Vector2(0.78, 0.78), Color(0.72, 0.94, 0.98, 0.34), -30)
	_add_tile_environment(root)
	_add_foreground_decor(root)
	_add_artificial_sun(root)
	_add_environment_fx(root)


func _add_parallax_layer(parent: Node, layer_name: String, texture_path: String, factor: float, base_pos: Vector2, sprite_scale: Vector2, color: Color, z: int) -> void:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z
	layer.set_meta("parallax_factor", factor)
	layer.set_meta("base_position", base_pos)
	parent.add_child(layer)
	parallax_layers.append(layer)

	var texture := _load_texture_runtime(texture_path)
	if texture is Texture2D:
		var step := maxf(float(texture.get_width()) * sprite_scale.x, 256.0)
		var repeat_count := int(ceil((level_width + 2400.0) / step)) + 4
		var start_x := -step * 2.0
		for index in range(repeat_count):
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(start_x + float(index) * step + base_pos.x, base_pos.y)
			sprite.scale = sprite_scale
			sprite.modulate = color
			layer.add_child(sprite)


func _add_tile_environment(parent: Node) -> void:
	var wall_texture := _load_texture_runtime(WALL_TEXTURE_PATH)
	var ceiling_texture := _load_texture_runtime(CEILING_TEXTURE_PATH)
	if ceiling_texture is Texture2D:
		_add_tile_strip(parent, ceiling_texture, "CeilingTile", floor_y - 610.0, -4, Color(0.52, 0.65, 0.66, 0.70), 1.0)
	if wall_texture is Texture2D:
		for x in [-72.0, level_width + 64.0]:
			for y in range(int(floor_y - 520.0), int(floor_y + 120.0), 96):
				var wall := Sprite2D.new()
				wall.name = "WallTile"
				wall.texture = wall_texture
				wall.z_index = 16
				wall.position = Vector2(x, float(y))
				wall.scale = Vector2.ONE
				wall.modulate = Color(0.45, 0.58, 0.60, 0.74)
				parent.add_child(wall)


func _add_foreground_decor(parent: Node) -> void:
	var texture := _load_texture_runtime(foreground_decor_texture_path)
	if not texture is Texture2D:
		return

	var scale_value := foreground_decor_scale
	var step := maxf(float(texture.get_width()) * scale_value * 0.98, 256.0)
	var repeat_count := int(ceil((level_width + step * 2.0) / step)) + 2
	var start_x := -step
	var bottom_y := floor_y + foreground_decor_bottom_offset
	var center_y := bottom_y - float(texture.get_height()) * scale_value * 0.5
	for index in range(repeat_count):
		var sprite := Sprite2D.new()
		sprite.name = "LevelForegroundDecor"
		sprite.texture = texture
		sprite.z_index = 12
		sprite.position = Vector2(start_x + float(index) * step, center_y)
		sprite.scale = Vector2.ONE * scale_value
		sprite.modulate = Color.WHITE
		parent.add_child(sprite)


func _add_tile_strip(parent: Node, texture: Texture2D, node_name: String, y: float, z: int, color: Color, scale_value: float) -> void:
	var step := maxf(float(texture.get_width()) * scale_value, 64.0)
	for x in range(-160, int(level_width) + 240, int(step)):
		var tile := Sprite2D.new()
		tile.name = node_name
		tile.texture = texture
		tile.z_index = z
		tile.centered = true
		tile.position = Vector2(float(x), y)
		tile.scale = Vector2.ONE * scale_value
		tile.modulate = color
		parent.add_child(tile)


func _add_tile_strip_variants(parent: Node, textures: Array[Texture2D], node_name: String, y: float, z: int, color: Color, scale_value: float) -> void:
	if textures.is_empty():
		return
	var step := maxf(float(textures[0].get_width()) * scale_value, 64.0)
	var index := 0
	for x in range(-160, int(level_width) + 240, int(step)):
		var tile := Sprite2D.new()
		tile.name = node_name
		tile.texture = textures[index % textures.size()]
		tile.z_index = z
		tile.centered = true
		tile.position = Vector2(float(x), y)
		tile.scale = Vector2.ONE * scale_value
		tile.modulate = color
		parent.add_child(tile)
		index += 1


func _add_environment_fx(parent: Node) -> void:
	_add_air_motes(parent)
	_add_water_glimmer(parent)


func _add_air_motes(parent: Node) -> void:
	if underwater_bubbles_only:
		_add_underwater_bubbles(parent)
		return

	var texture := load(GLOW_TEXTURE_PATH)
	if not texture is Texture2D:
		return

	_add_air_mote_layer(
		parent,
		"DemoAirMotesBack",
		12,
		-26,
		0.04,
		false,
		0.18,
		texture,
		Vector2(0.01, 0.02),
		Vector2(5.0, 16.0),
		Vector2(5.0, 14.0),
		Color(0.82, 0.94, 1.0, 1.0),
		Vector2(0.14, 0.32),
		Vector2(0.26, 0.46)
	)
	_add_air_mote_layer(
		parent,
		"DemoAirMotesMid",
		10,
		18,
		0.12,
		false,
		0.42,
		texture,
		Vector2(0.018, 0.038),
		Vector2(18.0, 58.0),
		Vector2(14.0, 31.0),
		Color(0.9, 0.97, 1.0, 1.0),
		Vector2(0.28, 0.62),
		Vector2(0.52, 0.82)
	)
	_add_air_mote_layer(
		parent,
		"DemoAirMotesFront",
		5,
		92,
		0.0,
		true,
		0.72,
		texture,
		Vector2(0.085, 0.18),
		Vector2(24.0, 62.0),
		Vector2(34.0, 86.0),
		Color(0.98, 1.0, 1.0, 1.0),
		Vector2(0.18, 0.42),
		Vector2(0.42, 0.76)
	)


func _add_underwater_bubbles(parent: Node) -> void:
	var texture := load(BUBBLE_TEXTURE_PATH)
	if not texture is Texture2D:
		return

	_add_air_mote_layer(parent, "DemoBubbleMotesBack", 18, -26, 0.04, false, 1.0, texture, Vector2(0.018, 0.034), Vector2(12.0, 26.0), Vector2(1.5, 6.0), Color(0.66, 0.92, 1.0, 1.0), Vector2(0.22, 0.42), Vector2(0.42, 0.66), true)
	_add_air_mote_layer(parent, "DemoBubbleMotesMid", 16, 18, 0.1, false, 1.0, texture, Vector2(0.028, 0.052), Vector2(18.0, 38.0), Vector2(2.0, 8.0), Color(0.72, 0.96, 1.0, 1.0), Vector2(0.3, 0.5), Vector2(0.52, 0.78), true)
	_add_air_mote_layer(parent, "DemoBubbleMotesFront", 8, 92, 0.0, true, 1.0, texture, Vector2(0.04, 0.075), Vector2(24.0, 52.0), Vector2(2.0, 9.0), Color(0.82, 0.98, 1.0, 1.0), Vector2(0.36, 0.56), Vector2(0.58, 0.84), true)


func _add_air_mote_layer(
	parent: Node,
	layer_name: String,
	count: int,
	z: int,
	parallax_factor: float,
	camera_relative: bool,
	upward_chance: float,
	texture: Texture2D,
	scale_range: Vector2,
	up_speed_range: Vector2,
	side_drift_range: Vector2,
	color: Color,
	alpha_min_range: Vector2,
	alpha_max_range: Vector2,
	is_bubble: bool = false
) -> void:
	var mote_root := Node2D.new()
	mote_root.name = layer_name
	mote_root.z_index = z
	mote_root.z_as_relative = false
	mote_root.set_meta("parallax_factor", parallax_factor)
	mote_root.set_meta("camera_relative", camera_relative)
	parent.add_child(mote_root)

	var top_y := floor_y - 620.0
	var bottom_y := floor_y + 90.0
	for index in range(count):
		var base_position := Vector2(randf_range(60.0, level_width - 60.0), randf_range(top_y, bottom_y))
		var mote := Node2D.new()
		mote.name = "%s_%02d" % [layer_name, index]
		mote.position = base_position
		mote_root.add_child(mote)

		var dot := Sprite2D.new()
		dot.texture = texture
		dot.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
		dot.modulate = Color(color.r, color.g, color.b, randf_range(alpha_min_range.x, alpha_max_range.y))
		mote.add_child(dot)

		var glow := PointLight2D.new()
		glow.texture = texture
		glow.energy = 0.0 if is_bubble else randf_range(0.025, 0.09)
		glow.texture_scale = randf_range(0.12, 0.24)
		glow.color = color
		glow.blend_mode = Light2D.BLEND_MODE_ADD as Light2D.BlendMode
		mote.add_child(glow)

		air_motes.append({
			"root": mote_root,
			"node": mote,
			"dot": dot,
			"light": glow,
			"base": base_position,
			"phase": randf_range(0.0, TAU),
			"x_amp": randf_range(side_drift_range.x, side_drift_range.y),
			"y_amp": randf_range(2.0, 12.0),
			"goes_up": randf() < upward_chance,
			"up_speed": randf_range(up_speed_range.x, up_speed_range.y),
			"side_speed": randf_range(0.45, 1.2),
			"flicker_speed": randf_range(1.4, 2.8),
			"min_alpha": randf_range(alpha_min_range.x, alpha_min_range.y),
			"max_alpha": randf_range(alpha_max_range.x, alpha_max_range.y),
			"min_energy": randf_range(0.015, 0.035),
			"max_energy": randf_range(0.055, 0.12),
			"top_y": top_y,
			"bottom_y": bottom_y,
			"left_x": -140.0,
			"right_x": level_width + 140.0,
			"camera_relative": camera_relative,
			"is_bubble": is_bubble,
		})


func _update_air_motes() -> void:
	var delta := get_process_delta_time()
	var camera := get_viewport().get_camera_2d()
	var camera_rect := _get_camera_world_rect(camera)
	for mote_data in air_motes:
		var mote := mote_data.get("node") as Node2D
		var dot := mote_data.get("dot") as Sprite2D
		var glow := mote_data.get("light") as PointLight2D
		if mote == null or dot == null or glow == null:
			continue
		var base: Vector2 = mote_data.get("base", Vector2.ZERO)
		var phase := float(mote_data.get("phase", 0.0))
		var goes_up := bool(mote_data.get("goes_up", true))
		if goes_up:
			base.y -= float(mote_data.get("up_speed", 24.0)) * delta
		var camera_relative := bool(mote_data.get("camera_relative", false))
		var top_y := float(mote_data.get("top_y", floor_y - 620.0))
		var bottom_y := float(mote_data.get("bottom_y", floor_y + 90.0))
		var left_x := float(mote_data.get("left_x", 0.0))
		var right_x := float(mote_data.get("right_x", level_width))
		if camera_relative and camera_rect.size != Vector2.ZERO:
			top_y = camera_rect.position.y - 120.0
			bottom_y = camera_rect.end.y + 130.0
			left_x = camera_rect.position.x - 180.0
			right_x = camera_rect.end.x + 180.0
		if goes_up and base.y < top_y:
			base.y = bottom_y + randf_range(0.0, 90.0)
			base.x = randf_range(left_x, right_x)
			phase = randf_range(0.0, TAU)
			mote_data["phase"] = phase
		if camera_relative and (base.x < left_x or base.x > right_x):
			base.x = randf_range(left_x, right_x)
		mote_data["base"] = base

		var parallax_offset := 0.0
		var root := mote_data.get("root") as Node2D
		if camera != null and root != null and not camera_relative:
			parallax_offset = -camera.global_position.x * float(root.get_meta("parallax_factor", 0.0))
		var t := atmosphere_time * float(mote_data.get("side_speed", 1.0)) + phase
		var idle_y := cos(t * 0.72) * float(mote_data.get("y_amp", 4.0)) if not goes_up else 0.0
		mote.position = base + Vector2(parallax_offset + sin(t) * float(mote_data.get("x_amp", 8.0)), idle_y)
		if bool(mote_data.get("is_bubble", false)):
			dot.modulate.a = float(mote_data.get("max_alpha", 0.72))
			glow.energy = 0.0
			continue
		var flicker := (sin(atmosphere_time * float(mote_data.get("flicker_speed", 2.0)) + phase * 1.7) + 1.0) * 0.5
		dot.modulate.a = lerpf(float(mote_data.get("min_alpha", 0.4)), float(mote_data.get("max_alpha", 0.9)), flicker)
		glow.energy = lerpf(float(mote_data.get("min_energy", 0.06)), float(mote_data.get("max_energy", 0.16)), flicker)


func _add_artificial_sun(parent: Node) -> void:
	if not artificial_sun_enabled:
		return

	var light := DirectionalLight2D.new()
	light.name = "ArtificialSunKeyLight"
	light.color = artificial_sun_color
	light.energy = artificial_sun_energy
	light.rotation_degrees = -36.0
	light.z_index = 210
	parent.add_child(light)

	var texture := _load_texture_runtime(GLOW_TEXTURE_PATH)
	if not texture is Texture2D:
		return

	var glow := Sprite2D.new()
	glow.name = "ArtificialSunSoftGlow"
	glow.texture = texture
	glow.position = artificial_sun_position
	glow.scale = Vector2.ONE * 5.5
	glow.z_index = -12
	glow.modulate = Color(artificial_sun_color.r, artificial_sun_color.g, artificial_sun_color.b, artificial_sun_glow_alpha)
	parent.add_child(glow)

	var fill := PointLight2D.new()
	fill.name = "ArtificialSunFillLight"
	fill.texture = texture
	fill.position = artificial_sun_position
	fill.color = artificial_sun_color
	fill.energy = artificial_sun_energy * 0.62
	fill.texture_scale = 4.8
	fill.blend_mode = Light2D.BLEND_MODE_ADD as Light2D.BlendMode
	parent.add_child(fill)


func _get_camera_world_rect(camera: Camera2D) -> Rect2:
	if camera == null:
		return Rect2()
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return Rect2()
	var zoom := camera.zoom
	if is_zero_approx(zoom.x) or is_zero_approx(zoom.y):
		return Rect2()
	var world_size := Vector2(viewport_size.x / zoom.x, viewport_size.y / zoom.y)
	return Rect2(camera.global_position - world_size * 0.5, world_size)


func _add_water_glimmer(parent: Node) -> void:
	var texture := load(WATER_TEXTURE_PATH)
	if not texture is Texture2D:
		return
	for index in range(5):
		var water := CPUParticles2D.new()
		water.name = "DemoWaterGlimmer%d" % index
		water.texture = texture
		water.z_index = 30
		water.position = Vector2(260.0 + float(index) * 420.0, floor_y - 16.0)
		water.amount = 18
		water.lifetime = 1.7
		water.preprocess = 1.7
		water.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		water.emission_rect_extents = Vector2(150.0, 4.0)
		water.direction = Vector2.UP
		water.spread = 52.0
		water.gravity = Vector2(0.0, 38.0)
		water.initial_velocity_min = 8.0
		water.initial_velocity_max = 36.0
		water.scale_amount_min = 0.012
		water.scale_amount_max = 0.035
		water.color = Color(0.5, 0.92, 1.0, 0.34)
		parent.add_child(water)
		water.emitting = true


func _load_floor_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in PAINTED_FLOOR_TEXTURE_PATHS:
		var texture := _load_texture_runtime(String(path))
		if texture is Texture2D:
			textures.append(texture)
	if textures.is_empty():
		var fallback := _load_texture_runtime(FLOOR_TEXTURE_PATH)
		if fallback is Texture2D:
			textures.append(fallback)
	return textures


func _load_texture_runtime(path: String) -> Texture2D:
	if path == "":
		return null
	if path.to_lower().ends_with(".png"):
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(path)) == OK:
			return ImageTexture.create_from_image(image)
	var resource := load(path)
	return resource if resource is Texture2D else null


func _update_parallax() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	for layer in parallax_layers:
		if not is_instance_valid(layer):
			continue
		var factor := float(layer.get_meta("parallax_factor", 0.0))
		layer.position.x = -camera.global_position.x * factor
		layer.position.y = 0.0


func _attach_player_glow() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player is Node2D:
		return
	if player_glow != null and is_instance_valid(player_glow):
		return

	player_glow = (player as Node2D).get_node_or_null("DemoPlayerGlow") as PointLight2D
	if player_glow == null:
		player_glow = PointLight2D.new()
		player_glow.name = "DemoPlayerGlow"
		(player as Node2D).add_child(player_glow)
	player_glow.texture = load(GLOW_TEXTURE_PATH)
	player_glow.color = Color(0.62, 0.9, 1.0, 1.0)
	player_glow.energy = 0.56
	player_glow.blend_mode = Light2D.BLEND_MODE_ADD as Light2D.BlendMode
	player_glow.texture_scale = maxf(player_glow_radius / 250.0, 0.45)
