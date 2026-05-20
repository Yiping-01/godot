extends CanvasLayer
class_name DemoLoadingTransition

const WALK_FRAMES := [
	"res://demo/assets/art/legacy/player/Walk/sea0_walk_1.png",
	"res://demo/assets/art/legacy/player/Walk/sea0_walk_2.png",
	"res://demo/assets/art/legacy/player/Walk/sea0_walk_3.png",
	"res://demo/assets/art/legacy/player/Walk/sea0_walk_4.png",
	"res://demo/assets/art/legacy/player/Walk/sea0_walk_5.png",
]

var label: Label
var runner: TextureRect
var progress_bar: ColorRect
var frame_index := 0
var frame_time := 0.0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func load_scene(path: String, minimum_time := 0.45) -> void:
	ResourceLoader.load_threaded_request(path)
	var elapsed := 0.0
	var progress: Array = []
	while true:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress) as ResourceLoader.ThreadLoadStatus
		var amount := float(progress[0]) if progress.size() > 0 else 0.0
		_update_loading(amount)
		if status == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= minimum_time:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			get_tree().change_scene_to_file(path)
			queue_free()
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	var scene := ResourceLoader.load_threaded_get(path)
	if scene is PackedScene:
		get_tree().change_scene_to_packed(scene)
	else:
		get_tree().change_scene_to_file(path)
	queue_free()


func _process(delta: float) -> void:
	frame_time += delta
	if frame_time >= 0.09:
		frame_time = 0.0
		frame_index = (frame_index + 1) % WALK_FRAMES.size()
		var texture := load(WALK_FRAMES[frame_index])
		if texture is Texture2D:
			runner.texture = texture


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.01, 0.014, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	label = Label.new()
	label.text = "LOADING"
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -210.0
	label.offset_top = -30.0
	label.offset_right = 210.0
	label.offset_bottom = 30.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color(0.85, 0.96, 0.96, 0.96))
	add_child(label)

	var line_bg := ColorRect.new()
	line_bg.color = Color(0.16, 0.32, 0.34, 0.38)
	line_bg.set_anchors_preset(Control.PRESET_CENTER)
	line_bg.offset_left = -145.0
	line_bg.offset_top = 38.0
	line_bg.offset_right = 145.0
	line_bg.offset_bottom = 42.0
	add_child(line_bg)

	progress_bar = ColorRect.new()
	progress_bar.color = Color(0.78, 0.94, 0.9, 0.86)
	progress_bar.position = Vector2(0, 0)
	progress_bar.size = Vector2(0, 4)
	line_bg.add_child(progress_bar)

	runner = TextureRect.new()
	runner.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	runner.offset_left = -180.0
	runner.offset_top = -150.0
	runner.offset_right = -56.0
	runner.offset_bottom = -40.0
	runner.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	runner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	runner.flip_h = true
	var texture := load(WALK_FRAMES[0])
	if texture is Texture2D:
		runner.texture = texture
	add_child(runner)


func _update_loading(amount: float) -> void:
	progress_bar.size.x = lerpf(progress_bar.size.x, 290.0 * clampf(amount, 0.0, 1.0), 0.35)
