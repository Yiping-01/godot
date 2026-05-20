extends SceneTree

const TILE_IMAGE_PATH := "res://hulobOuO/assets/tiles/ocean_rock_modular_tiles.png"
const TILESET_PATH := "res://hulobOuO/assets/tiles/ocean_rock_modular_tileset.tres"
const WORKSPACE_SCENE_PATH := "res://hulobOuO/tile_paint_workspace.tscn"
const TILE_SIZE := Vector2i(181, 155)
const COLUMNS := 8
const ROWS := 7


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var texture := load(TILE_IMAGE_PATH) as Texture2D
	if texture == null:
		push_error("Cannot load ocean tile image: " + TILE_IMAGE_PATH)
		quit(1)
		return
	var tile_set := _create_tileset(texture)
	ResourceSaver.save(tile_set, TILESET_PATH)
	var saved_tile_set := load(TILESET_PATH) as TileSet
	var scene := _create_workspace_scene(saved_tile_set)
	ResourceSaver.save(scene, WORKSPACE_SCENE_PATH)
	quit(0)


func _create_tileset(texture: Texture2D) -> TileSet:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE

	for y in ROWS:
		for x in COLUMNS:
			atlas.create_tile(Vector2i(x, y))

	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 2)
	tile_set.add_source(atlas, 0)

	for y in ROWS:
		for x in COLUMNS:
			var data := atlas.get_tile_data(Vector2i(x, y), 0)
			if data == null:
				continue
			_add_collision(data, y)

	return tile_set


func _add_collision(data: TileData, row: int) -> void:
	data.set_collision_polygons_count(0, 1)
	var inset := 10.0
	var top := 8.0
	var bottom := float(TILE_SIZE.y - 8)
	var points := PackedVector2Array([
		Vector2(inset, top),
		Vector2(float(TILE_SIZE.x) - inset, top),
		Vector2(float(TILE_SIZE.x) - inset, bottom),
		Vector2(inset, bottom),
	])
	if row == 4:
		points = PackedVector2Array([
			Vector2(10, 120),
			Vector2(float(TILE_SIZE.x) - 10, 120),
			Vector2(float(TILE_SIZE.x) - 10, bottom),
			Vector2(10, bottom),
		])
	elif row == 5:
		points = PackedVector2Array([
			Vector2(20, 12),
			Vector2(float(TILE_SIZE.x) - 20, 12),
			Vector2(float(TILE_SIZE.x) * 0.5, bottom),
		])
	data.set_collision_polygon_points(0, 0, points)


func _create_workspace_scene(tile_set: TileSet) -> PackedScene:
	var root := Node2D.new()
	root.name = "TilePaintWorkspace"
	root.set_script(load("res://hulobOuO/scripts/tile_workspace.gd"))

	var atmosphere := Node2D.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_script(load("res://hulobOuO/scripts/hulob_atmosphere.gd"))
	atmosphere.set("environment_tint", Color(0.18, 0.27, 0.30, 1.0))
	atmosphere.set("player_glow_radius", 420.0)
	atmosphere.set("level_width", 5200.0)
	atmosphere.set("floor_y", 880.0)
	_add_owned(root, atmosphere)

	var canvas := CanvasModulate.new()
	canvas.name = "HulobCanvasModulate"
	canvas.color = Color(0.18, 0.27, 0.30, 1.0)
	_add_owned(atmosphere, canvas, root)

	var background := Polygon2D.new()
	background.name = "DeepSeaBackdrop"
	background.z_index = -60
	background.color = Color(0.035, 0.09, 0.12, 1.0)
	background.polygon = PackedVector2Array([
		Vector2(-900, -600),
		Vector2(5600, -600),
		Vector2(5600, 1500),
		Vector2(-900, 1500),
	])
	_add_owned(root, background)

	var paint_layer := TileMapLayer.new()
	paint_layer.name = "PaintHere_TileMapLayer"
	paint_layer.tile_set = tile_set
	_add_owned(root, paint_layer)
	_paint_sample_map(paint_layer)

	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(360, 610)
	player.set("camera_follow_position", Vector2(20, 96))
	player.set("camera_follow_zoom", Vector2(1.18, 1.18))
	player.set("camera_follow_smoothing_speed", 8.5)
	_add_owned(root, player)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/health_ui.gd"))
	_add_owned(root, hud)

	var exit_menu := CanvasLayer.new()
	exit_menu.name = "ExitMenu"
	exit_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	exit_menu.set_script(load("res://hulobOuO/scripts/hulob_exit_menu.gd"))
	_add_owned(root, exit_menu)

	var game_ui_scene := load("res://scenes/game_ui.tscn") as PackedScene
	var game_ui := game_ui_scene.instantiate()
	game_ui.name = "GameUI"
	_add_owned(root, game_ui)

	var camera := Camera2D.new()
	camera.name = "EditorPreviewCamera"
	camera.position = Vector2(840, 420)
	camera.zoom = Vector2(0.78, 0.78)
	camera.enabled = false
	_add_owned(root, camera)

	var packed := PackedScene.new()
	packed.pack(root)
	return packed


func _paint_sample_map(layer: TileMapLayer) -> void:
	for x in range(-2, 22):
		layer.set_cell(Vector2i(x, 5), 0, Vector2i(0, 0))
	for x in range(4, 10):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(0, 3))
	for x in range(13, 18):
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(2, 4), 0, Vector2i(5, 0))
	layer.set_cell(Vector2i(3, 4), 0, Vector2i(6, 0))
	layer.set_cell(Vector2i(10, 4), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(11, 4), 0, Vector2i(3, 4))
	layer.set_cell(Vector2i(17, 4), 0, Vector2i(7, 5))
	layer.set_cell(Vector2i(18, 4), 0, Vector2i(4, 5))


func _add_owned(parent: Node, child: Node, owner_root: Node = null) -> void:
	parent.add_child(child)
	child.owner = parent if owner_root == null else owner_root
