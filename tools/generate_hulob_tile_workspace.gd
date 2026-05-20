extends SceneTree

const TILE_SIZE := 32
const COLUMNS := 8
const ROWS := 4
const TILE_DIR := "res://hulobOuO/assets/tiles"
const TILE_IMAGE_PATH := "res://hulobOuO/assets/tiles/hulob_floor_tilesheet.png"
const TILESET_PATH := "res://hulobOuO/assets/tiles/hulob_floor_tileset.tres"
const WORKSPACE_SCENE_PATH := "res://hulobOuO/tile_paint_workspace.tscn"

var rng := RandomNumberGenerator.new()
var image: Image


func _initialize() -> void:
	rng.seed = 20260520
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TILE_DIR))
	_create_tilesheet()
	_create_tileset_and_workspace()
	quit(0)


func _create_tilesheet() -> void:
	image = Image.create(TILE_SIZE * COLUMNS, TILE_SIZE * ROWS, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	_paint_tile(Vector2i(0, 0), "solid")
	_paint_tile(Vector2i(1, 0), "top")
	_paint_tile(Vector2i(2, 0), "bottom")
	_paint_tile(Vector2i(3, 0), "left")
	_paint_tile(Vector2i(4, 0), "right")
	_paint_tile(Vector2i(5, 0), "top_left")
	_paint_tile(Vector2i(6, 0), "top_right")
	_paint_tile(Vector2i(7, 0), "cracked")

	_paint_tile(Vector2i(0, 1), "platform_mid")
	_paint_tile(Vector2i(1, 1), "platform_left")
	_paint_tile(Vector2i(2, 1), "platform_right")
	_paint_tile(Vector2i(3, 1), "thin_bridge")
	_paint_tile(Vector2i(4, 1), "wet_wall")
	_paint_tile(Vector2i(5, 1), "wet_wall_crack")
	_paint_tile(Vector2i(6, 1), "dark_fill")
	_paint_tile(Vector2i(7, 1), "small_stones")

	_paint_tile(Vector2i(0, 2), "water_floor")
	_paint_tile(Vector2i(1, 2), "water_top")
	_paint_tile(Vector2i(2, 2), "water_wall")
	_paint_tile(Vector2i(3, 2), "coral_shadow")
	_paint_tile(Vector2i(4, 2), "seaweed_shadow")
	_paint_tile(Vector2i(5, 2), "pillar")
	_paint_tile(Vector2i(6, 2), "pillar_top")
	_paint_tile(Vector2i(7, 2), "pillar_broken")

	_paint_tile(Vector2i(0, 3), "boss_floor")
	_paint_tile(Vector2i(1, 3), "boss_top")
	_paint_tile(Vector2i(2, 3), "boss_crack")
	_paint_tile(Vector2i(3, 3), "boss_plate")
	_paint_tile(Vector2i(4, 3), "glow_ore")
	_paint_tile(Vector2i(5, 3), "edge_shadow")
	_paint_tile(Vector2i(6, 3), "empty")
	_paint_tile(Vector2i(7, 3), "empty")

	image.save_png(TILE_IMAGE_PATH)


func _create_tileset_and_workspace() -> void:
	var texture := ImageTexture.create_from_image(image)
	texture.resource_path = TILE_IMAGE_PATH

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in ROWS:
		for x in COLUMNS:
			atlas.create_tile(Vector2i(x, y))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(atlas, 0)
	ResourceSaver.save(tile_set, TILESET_PATH)

	var root := Node2D.new()
	root.name = "TilePaintWorkspace"

	var tilemap := TileMapLayer.new()
	tilemap.name = "PaintHere_TileMapLayer"
	tilemap.tile_set = tile_set
	root.add_child(tilemap)
	tilemap.owner = root

	for x in range(-10, 24):
		tilemap.set_cell(Vector2i(x, 10), 0, Vector2i(0, 0))
		tilemap.set_cell(Vector2i(x, 9), 0, Vector2i(1, 0))
	for x in range(-4, 5):
		tilemap.set_cell(Vector2i(x, 4), 0, Vector2i(0, 1))
	tilemap.set_cell(Vector2i(-5, 4), 0, Vector2i(1, 1))
	tilemap.set_cell(Vector2i(5, 4), 0, Vector2i(2, 1))
	for x in range(11, 18):
		tilemap.set_cell(Vector2i(x, 6), 0, Vector2i(0, 3))
		tilemap.set_cell(Vector2i(x, 5), 0, Vector2i(1, 3))

	var guide := TileMapLayer.new()
	guide.name = "ReferenceTiles_DoNotPaint"
	guide.tile_set = tile_set
	guide.position = Vector2(0, -192)
	root.add_child(guide)
	guide.owner = root
	for y in ROWS:
		for x in COLUMNS:
			guide.set_cell(Vector2i(x, y), 0, Vector2i(x, y))

	var camera := Camera2D.new()
	camera.name = "EditorPreviewCamera"
	camera.position = Vector2(240, 176)
	camera.zoom = Vector2(1.35, 1.35)
	camera.enabled = true
	root.add_child(camera)
	camera.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, WORKSPACE_SCENE_PATH)


func _paint_tile(cell: Vector2i, kind: String) -> void:
	var origin := cell * TILE_SIZE
	var base := Color(0.11, 0.22, 0.24, 1.0)
	var mid := Color(0.18, 0.34, 0.36, 1.0)
	var light := Color(0.42, 0.84, 0.88, 1.0)
	var dark := Color(0.035, 0.07, 0.08, 1.0)

	_fill(origin, base)
	_noise(origin, 0.035)
	_draw_edge(origin, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Color(0.06, 0.12, 0.13, 0.55))

	match kind:
		"top", "top_left", "top_right", "water_top", "boss_top":
			_rect(origin + Vector2i(0, 0), Vector2i(32, 6), light)
			_rect(origin + Vector2i(0, 6), Vector2i(32, 3), Color(0.24, 0.5, 0.52, 1))
		"bottom":
			_rect(origin + Vector2i(0, 24), Vector2i(32, 8), dark)
		"left", "top_left":
			_rect(origin + Vector2i(0, 0), Vector2i(5, 32), dark)
		"right", "top_right":
			_rect(origin + Vector2i(27, 0), Vector2i(5, 32), dark)
		"cracked", "wet_wall_crack", "boss_crack":
			_crack(origin, Vector2i(7, 5), [Vector2i(13, 11), Vector2i(10, 18), Vector2i(18, 27)])
		"platform_mid", "platform_left", "platform_right", "thin_bridge":
			_fill(origin, Color(0.16, 0.29, 0.30, 1))
			_rect(origin + Vector2i(0, 0), Vector2i(32, 5), light)
			_rect(origin + Vector2i(0, 22), Vector2i(32, 10), Color(0.055, 0.1, 0.11, 1))
			if kind == "platform_left":
				_rect(origin + Vector2i(0, 0), Vector2i(5, 32), dark)
			elif kind == "platform_right":
				_rect(origin + Vector2i(27, 0), Vector2i(5, 32), dark)
			elif kind == "thin_bridge":
				_rect(origin + Vector2i(0, 13), Vector2i(32, 8), light)
		"wet_wall", "water_wall":
			_fill(origin, Color(0.07, 0.17, 0.19, 1))
			_rect(origin + Vector2i(24, 0), Vector2i(5, 32), Color(0.23, 0.48, 0.5, 1))
			_noise(origin, 0.05)
		"dark_fill":
			_fill(origin, Color(0.025, 0.05, 0.055, 1))
		"small_stones":
			for i in 9:
				_circle(origin + Vector2i(rng.randi_range(5, 27), rng.randi_range(8, 27)), rng.randi_range(1, 3), mid)
		"water_floor":
			_fill(origin, Color(0.07, 0.24, 0.28, 1))
			_rect(origin + Vector2i(0, 2), Vector2i(32, 3), Color(0.46, 0.92, 0.98, 1))
		"coral_shadow":
			_fill(origin, Color(0.06, 0.16, 0.18, 1))
			_crack(origin, Vector2i(7, 27), [Vector2i(11, 17), Vector2i(8, 8), Vector2i(14, 16), Vector2i(20, 7)])
		"seaweed_shadow":
			_fill(origin, Color(0.055, 0.15, 0.17, 1))
			for x in [8, 15, 22]:
				_crack(origin, Vector2i(x, 29), [Vector2i(x + rng.randi_range(-3, 3), 18), Vector2i(x + rng.randi_range(-4, 4), 8)])
		"pillar", "pillar_top", "pillar_broken":
			_fill(origin, Color(0.08, 0.19, 0.2, 1))
			_rect(origin + Vector2i(6, 0), Vector2i(20, 32), Color(0.13, 0.27, 0.28, 1))
			if kind != "pillar":
				_rect(origin + Vector2i(3, 0), Vector2i(26, 7), light)
			if kind == "pillar_broken":
				_crack(origin, Vector2i(10, 3), [Vector2i(19, 9), Vector2i(12, 16)])
		"boss_floor", "boss_plate":
			_fill(origin, Color(0.13, 0.19, 0.2, 1))
			_rect(origin + Vector2i(0, 24), Vector2i(32, 8), Color(0.04, 0.08, 0.09, 1))
			if kind == "boss_plate":
				_rect(origin + Vector2i(5, 8), Vector2i(22, 12), Color(0.2, 0.28, 0.29, 1))
		"glow_ore":
			_fill(origin, Color(0.08, 0.17, 0.18, 1))
			_circle(origin + Vector2i(16, 16), 5, Color(0.54, 0.96, 1, 1))
			_circle(origin + Vector2i(16, 16), 2, Color(0.9, 1, 1, 1))
		"edge_shadow":
			_fill(origin, Color(0.02, 0.045, 0.05, 1))
		"empty":
			_fill(origin, Color(0, 0, 0, 0))


func _fill(origin: Vector2i, color: Color) -> void:
	_rect(origin, Vector2i(TILE_SIZE, TILE_SIZE), color)


func _rect(origin: Vector2i, size: Vector2i, color: Color) -> void:
	for y in range(size.y):
		for x in range(size.x):
			image.set_pixel(origin.x + x, origin.y + y, color)


func _draw_edge(origin: Vector2i, rect: Rect2i, color: Color) -> void:
	for x in range(rect.size.x):
		image.set_pixel(origin.x + x, origin.y, color)
		image.set_pixel(origin.x + x, origin.y + rect.size.y - 1, color)
	for y in range(rect.size.y):
		image.set_pixel(origin.x, origin.y + y, color)
		image.set_pixel(origin.x + rect.size.x - 1, origin.y + y, color)


func _noise(origin: Vector2i, amount: float) -> void:
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			if rng.randf() < 0.18:
				var current := image.get_pixel(origin.x + x, origin.y + y)
				var delta := rng.randf_range(-amount, amount)
				image.set_pixel(origin.x + x, origin.y + y, current.lightened(delta) if delta > 0.0 else current.darkened(-delta))


func _crack(origin: Vector2i, start: Vector2i, points: Array) -> void:
	var previous := start
	for point in points:
		_line(origin + previous, origin + point, Color(0.015, 0.035, 0.04, 0.9))
		previous = point


func _line(a: Vector2i, b: Vector2i, color: Color) -> void:
	var steps: int = max(abs(b.x - a.x), abs(b.y - a.y))
	for i in range(steps + 1):
		var t := float(i) / float(max(steps, 1))
		var p := Vector2i(roundi(lerpf(float(a.x), float(b.x), t)), roundi(lerpf(float(a.y), float(b.y), t)))
		image.set_pixelv(p, color)


func _circle(center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				image.set_pixel(center.x + x, center.y + y, color)
