extends Node

signal controls_changed

const SAVE_PATH := "user://input_settings.cfg"
const ACTIONS := [
	{"action": "move_up", "label": "上"},
	{"action": "move_down", "label": "下"},
	{"action": "move_left", "label": "左"},
	{"action": "move_right", "label": "右"},
	{"action": "jump", "label": "跳躍"},
	{"action": "attack", "label": "攻擊"},
	{"action": "dash", "label": "衝刺"},
	{"action": "far_attack", "label": "遠攻"},
	{"action": "skill_group_switch", "label": "切換技能組"},
	{"action": "interact", "label": "互動 / 藥水"},
	{"action": "map", "label": "地圖"},
	{"action": "inventory", "label": "物品欄"},
	{"action": "audio_settings", "label": "聲音"},
]

var _loaded := false


func _ready() -> void:
	load_bindings()


func get_actions() -> Array:
	return ACTIONS


func get_label_for_action(action: String) -> String:
	var input := InputHelper.get_keyboard_input_for_action(action)
	if input == null:
		return "-"
	return InputHelper.get_label_for_input(input)


func format_action_text(text: String) -> String:
	var formatted := text
	for item in ACTIONS:
		var action := String(item["action"])
		formatted = formatted.replace("{%s}" % action, get_label_for_action(action))

	formatted = formatted.replace("A / D", "%s / %s" % [get_label_for_action("move_left"), get_label_for_action("move_right")])
	formatted = formatted.replace("W / S", "%s / %s" % [get_label_for_action("move_up"), get_label_for_action("move_down")])
	formatted = formatted.replace("S+X", "%s+%s" % [get_label_for_action("move_down"), get_label_for_action("attack")])

	formatted = formatted.replace("按 E", "按 %s" % get_label_for_action("interact"))
	formatted = formatted.replace("按下E", "按下%s" % get_label_for_action("interact"))
	formatted = formatted.replace("E：", "%s：" % get_label_for_action("interact"))
	formatted = formatted.replace("E 是互動鍵", "%s 是互動鍵" % get_label_for_action("interact"))

	formatted = formatted.replace("按 I", "按 %s" % get_label_for_action("inventory"))
	formatted = formatted.replace("I 或", "%s 或" % get_label_for_action("inventory"))
	formatted = formatted.replace("I 開", "%s 開" % get_label_for_action("inventory"))
	formatted = formatted.replace("I /", "%s /" % get_label_for_action("inventory"))

	formatted = formatted.replace("按 M", "按 %s" % get_label_for_action("map"))
	formatted = formatted.replace("M 或", "%s 或" % get_label_for_action("map"))
	formatted = formatted.replace("M 開", "%s 開" % get_label_for_action("map"))
	formatted = formatted.replace("M /", "%s /" % get_label_for_action("map"))

	formatted = formatted.replace("按 Z", "按 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("按下 Z", "按下 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("按下兩下 Z", "按下兩下 %s" % get_label_for_action("jump"))
	formatted = formatted.replace("Z是跳躍", "%s是跳躍" % get_label_for_action("jump"))
	formatted = formatted.replace("Z 是跳躍", "%s 是跳躍" % get_label_for_action("jump"))
	formatted = formatted.replace("Z：", "%s：" % get_label_for_action("jump"))

	formatted = formatted.replace("按 X", "按 %s" % get_label_for_action("attack"))
	formatted = formatted.replace("X是攻擊", "%s是攻擊" % get_label_for_action("attack"))
	formatted = formatted.replace("X 是近戰攻擊", "%s 是近戰攻擊" % get_label_for_action("attack"))
	formatted = formatted.replace("X：", "%s：" % get_label_for_action("attack"))

	formatted = formatted.replace("按 C", "按 %s" % get_label_for_action("dash"))
	formatted = formatted.replace("按下C", "按下%s" % get_label_for_action("dash"))
	formatted = formatted.replace("C可進行衝刺", "%s可進行衝刺" % get_label_for_action("dash"))
	formatted = formatted.replace("C 可進行衝刺", "%s 可進行衝刺" % get_label_for_action("dash"))
	formatted = formatted.replace("C：", "%s：" % get_label_for_action("dash"))

	formatted = formatted.replace("按 F", "按 %s" % get_label_for_action("far_attack"))
	formatted = formatted.replace("F 是遠距離水波", "%s 是遠距離水波" % get_label_for_action("far_attack"))
	formatted = formatted.replace("F 技能", "%s 技能" % get_label_for_action("far_attack"))
	formatted = formatted.replace("F：", "%s：" % get_label_for_action("far_attack"))
	formatted = formatted.replace("按 R", "按 %s" % get_label_for_action("skill_group_switch"))
	formatted = formatted.replace("R 切換", "%s 切換" % get_label_for_action("skill_group_switch"))
	formatted = formatted.replace("P 調整", "%s 調整" % get_label_for_action("audio_settings"))
	return formatted


func rebind_keyboard_action(action: String, event: InputEventKey) -> Error:
	if not InputMap.has_action(action):
		return ERR_DOES_NOT_EXIST

	var next_event := event.duplicate()
	next_event.pressed = false
	next_event.echo = false
	var result: Error = InputHelper.set_keyboard_input_for_action(action, next_event, false)
	if result == OK:
		save_bindings()
		controls_changed.emit()
	return result


func reset_to_defaults() -> void:
	InputHelper.reset_all_actions()
	save_bindings()
	controls_changed.emit()


func save_bindings() -> void:
	var action_names := PackedStringArray()
	for item in ACTIONS:
		action_names.append(String(item["action"]))

	var config := ConfigFile.new()
	config.set_value("input", "bindings", InputHelper.serialize_inputs_for_actions(action_names))
	config.save(SAVE_PATH)


func load_bindings() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	var bindings := String(config.get_value("input", "bindings", ""))
	if bindings == "":
		return

	InputHelper.deserialize_inputs_for_actions(bindings)
	controls_changed.emit()
