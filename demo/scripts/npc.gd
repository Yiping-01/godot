extends Node2D
class_name ShopNpc

@export var display_name := "回收站商人"
@export_multiline var prompt_text := "按 E 對話"
@export var opens_shop := true
@export var dialogue_lines: Array[String] = [
	"這片海溝裡有很多被沖下來的寶特瓶。撿回來，我可以幫你換成補給。",
	"別急著硬衝。先看清楚怪物的預備動作，再找空檔反擊。",
]
@export var shop_items: Array[Dictionary] = [
	{"name": "回復藥水", "price": 4, "description": "補回一次生命。最多可攜帶五瓶。"},
	{"name": "粗糙護符", "price": 6, "description": "用回收零件拼成的護符，象徵把廢棄物重新利用。"},
	{"name": "破舊地圖", "price": 8, "description": "標記附近通道，讓探索方向更清楚。"},
	{"name": "旅行筆記", "price": 3, "description": "記錄海溝中的觀察與警示。"},
]

var offered_shop_items: Array[Dictionary] = []
var player_nearby := false
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	GameState.clear_scene_health_potion_purchase()
	_roll_shop_items()
	_refresh_prompt_text()
	prompt_label.hide()
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)
	var input_settings := get_node_or_null("/root/InputSettings")
	if input_settings != null:
		input_settings.connect("controls_changed", Callable(self, "_refresh_prompt_text"))


func get_shop_items() -> Array[Dictionary]:
	return offered_shop_items


func _roll_shop_items() -> void:
	offered_shop_items.assign(shop_items)
	offered_shop_items.shuffle()

	if offered_shop_items.size() > 3:
		offered_shop_items.resize(3)


func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby:
		return

	if event.is_action_pressed("interact") and not GameState.input_locked:
		var ui := get_tree().get_first_node_in_group("game_ui")
		if ui != null:
			if ui.has_method("set_world_prompt_active"):
				ui.set_world_prompt_active(self, false)
			prompt_label.hide()
			ui.open_npc_dialogue(self)
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		if ui.has_method("set_world_prompt_active"):
			ui.set_world_prompt_active(self, true)
	_refresh_prompt_text()
	prompt_label.show()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player_nearby = false
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		if ui.has_method("set_world_prompt_active"):
			ui.set_world_prompt_active(self, false)
	prompt_label.hide()


func _refresh_prompt_text() -> void:
	var input_settings := get_node_or_null("/root/InputSettings")
	prompt_label.text = prompt_text if input_settings == null else String(input_settings.call("format_action_text", prompt_text))
