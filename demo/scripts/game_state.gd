extends Node

signal currency_changed(amount: int)
signal inventory_changed(items: Dictionary)
signal health_potions_changed(amount: int)
signal equipped_skills_changed(skill_icons: Array)
signal active_skill_group_changed(group_index: int)
signal ultimate_charge_changed(current_charge: float, max_charge: float)
signal input_lock_changed(locked: bool)
signal first_item_obtained(item_name: String)
signal map_room_changed(scene_path: String, room_id: String)

const SAVE_PATH := "user://save.cfg"
const CONTINUE_SCENE_SAVE_PATH := "user://continue_scene.cfg"
const DEFAULT_START_SCENE := "res://demo/scenes/levels/demo_level_1.tscn"
const HEALTH_POTION_ITEM := "Health Potion"
const HEALTH_POSITION_ITEM := "health_position"
const STARTING_HEALTH_POTIONS := 3
const MAX_HEALTH_POTIONS := 5
const STARTER_ITEM := "旅行者筆記"
const DEFAULT_SKILL_ID := "water_shot"
const DEFAULT_SKILL_ICON := "res://demo/assets/art/legacy/player/attack_far/far_3.png"

var demo_start_fresh := true
var load_save_on_start := false

var currency: int = 0
var inventory: Dictionary = {
	STARTER_ITEM: 1,
	HEALTH_POSITION_ITEM: STARTING_HEALTH_POTIONS,
}
var item_database: Dictionary = {
	HEALTH_POTION_ITEM: {
		"display_name": "回復藥水",
		"description": "按下E鍵回復生命",
	},
	HEALTH_POSITION_ITEM: {
		"display_name": "回復藥水",
		"description": "按下E鍵回復生命",
	},
	STARTER_ITEM: {
		"display_name": "旅行者筆記",
		"description": "一份簡單的冒險紀錄，用來提醒你目前學過的操作。",
	},
	"粗糙護符": {
		"display_name": "粗糙護符",
		"description": "商人販售的暫時道具，目前只會收進背包。",
	},
	"生命碎片": {
		"display_name": "生命碎片",
		"description": "暫時的血量道具，之後可以改成提升最大生命。",
	},
	"破舊地圖": {
		"display_name": "破舊地圖",
		"description": "記錄附近房間配置的道具，之後可接上地圖 UI。",
	},
}
var input_locked := false
var has_shown_inventory_tutorial := false
var saved_respawn_position := Vector2.ZERO
var has_saved_respawn := false
var pending_spawn_position := Vector2.ZERO
var has_pending_spawn := false
var pending_spawn_marker_name := ""
var current_map_scene := ""
var current_map_room := ""
var equipped_skill_icons: Array[String] = [DEFAULT_SKILL_ICON, "", "", ""]
var equipped_skill_ids: Array[String] = [DEFAULT_SKILL_ID, "", "", ""]
var active_skill_group := 0
var ultimate_charge := 0.0
var ultimate_charge_max := 100.0
var map_rooms: Dictionary = {}
var visited_rooms: Dictionary = {}
var scene_health_potion_purchases: Dictionary = {}
var scene_rough_charm_purchases: Dictionary = {}
var player_current_health := -1.0
var player_max_health := 0
var player_current_stamina := -1.0
var player_max_stamina := 0.0
var continue_scene_path := DEFAULT_START_SCENE
var continue_player_position := Vector2.ZERO
var has_continue_player_position := false
var continue_spawn_marker_name := ""
var has_continue_spawn_marker := false
var pending_transition_shake_duration := 0.0
var pending_transition_shake_strength := 0.0
var pending_transition_title := ""
var pending_transition_subtitle := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if demo_start_fresh:
		reset_demo_state()
		load_game()
	merge_health_potion_items()
	currency_changed.emit(currency)
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())


func reset_demo_state() -> void:
	currency = 0
	currency_changed.emit(currency)

	inventory = {
		STARTER_ITEM: 1,
		HEALTH_POSITION_ITEM: STARTING_HEALTH_POTIONS,
	}
	has_saved_respawn = false
	saved_respawn_position = Vector2.ZERO
	has_pending_spawn = false
	pending_spawn_position = Vector2.ZERO
	pending_spawn_marker_name = ""
	has_shown_inventory_tutorial = false
	input_locked = false
	current_map_scene = ""
	current_map_room = ""
	equipped_skill_icons = [DEFAULT_SKILL_ICON, "", "", ""]
	equipped_skill_ids = [DEFAULT_SKILL_ID, "", "", ""]
	active_skill_group = 0
	ultimate_charge = 0.0
	map_rooms.clear()
	visited_rooms.clear()
	scene_health_potion_purchases.clear()
	scene_rough_charm_purchases.clear()
	clear_pending_transition_shake()
	clear_pending_transition_title()
	clear_player_runtime_status()
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())
	equipped_skills_changed.emit(equipped_skill_icons)
	active_skill_group_changed.emit(active_skill_group)
	ultimate_charge_changed.emit(ultimate_charge, ultimate_charge_max)


func set_input_locked(locked: bool) -> void:
	if input_locked == locked:
		return

	input_locked = locked
	input_lock_changed.emit(input_locked)


func set_pending_transition_shake(duration: float, strength: float) -> void:
	pending_transition_shake_duration = maxf(duration, 0.0)
	pending_transition_shake_strength = maxf(strength, 0.0)


func consume_pending_transition_shake() -> Dictionary:
	var shake := {
		"duration": pending_transition_shake_duration,
		"strength": pending_transition_shake_strength,
	}
	clear_pending_transition_shake()
	return shake


func clear_pending_transition_shake() -> void:
	pending_transition_shake_duration = 0.0
	pending_transition_shake_strength = 0.0


func set_pending_transition_title(title: String, subtitle: String) -> void:
	pending_transition_title = title
	pending_transition_subtitle = subtitle


func consume_pending_transition_title() -> Dictionary:
	var title_data: Dictionary = {
		"title": pending_transition_title,
		"subtitle": pending_transition_subtitle,
	}
	clear_pending_transition_title()
	return title_data


func clear_pending_transition_title() -> void:
	pending_transition_title = ""
	pending_transition_subtitle = ""


func has_player_runtime_status() -> bool:
	return player_current_health >= 0.0 and player_max_health > 0


func set_player_runtime_status(current_health: float, max_health: int, current_stamina: float, max_stamina: float) -> void:
	player_current_health = clampf(current_health, 0.0, float(max_health))
	player_max_health = max_health
	player_current_stamina = clampf(current_stamina, 0.0, max_stamina)
	player_max_stamina = max_stamina


func clear_player_runtime_status() -> void:
	player_current_health = -1.0
	player_max_health = 0
	player_current_stamina = -1.0
	player_max_stamina = 0.0


func add_currency(amount: int) -> void:
	currency = maxi(currency + amount, 0)
	currency_changed.emit(currency)
	save_game()


func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false

	currency -= amount
	currency_changed.emit(currency)
	save_game()
	return true


func add_item(item_name: String, amount: int = 1) -> void:
	item_name = get_inventory_item_name(item_name)
	var was_empty := inventory.is_empty()
	var had_item := has_item(item_name)
	inventory[item_name] = int(inventory.get(item_name, 0)) + amount
	inventory_changed.emit(inventory)
	if is_health_potion_item(item_name):
		health_potions_changed.emit(get_health_potion_count())

	if was_empty or not had_item:
		first_item_obtained.emit(item_name)


func has_item(item_name: String) -> bool:
	item_name = get_inventory_item_name(item_name)
	return int(inventory.get(item_name, 0)) > 0


func get_health_potion_count() -> int:
	return int(inventory.get(HEALTH_POSITION_ITEM, 0)) + int(inventory.get(HEALTH_POTION_ITEM, 0))


func can_add_health_potion() -> bool:
	return get_health_potion_count() < MAX_HEALTH_POTIONS


func add_health_potions(amount: int) -> void:
	if amount <= 0:
		return

	var current_amount := get_health_potion_count()
	var added_amount := mini(amount, MAX_HEALTH_POTIONS - current_amount)
	if added_amount <= 0:
		return

	add_item(HEALTH_POSITION_ITEM, added_amount)


func is_health_potion_item(item_name: String) -> bool:
	var normalized := item_name.strip_edges().to_lower()
	return item_name == HEALTH_POTION_ITEM or normalized == "health_potion" or normalized == HEALTH_POSITION_ITEM or item_name == "回復藥水"


func is_rough_charm_item(item_name: String) -> bool:
	return item_name == "粗糙護符"


func get_inventory_item_name(item_name: String) -> String:
	if is_health_potion_item(item_name):
		return HEALTH_POSITION_ITEM

	return item_name


func merge_health_potion_items() -> void:
	var total := 0
	var found_health_potion_item := false

	for item_name in inventory.keys():
		if is_health_potion_item(String(item_name)):
			total += int(inventory[item_name])
			found_health_potion_item = true

	if not found_health_potion_item:
		return

	for item_name in inventory.keys():
		if is_health_potion_item(String(item_name)):
			inventory.erase(item_name)

	inventory[HEALTH_POSITION_ITEM] = mini(total, MAX_HEALTH_POTIONS)


func get_scene_purchase_key(scene_path: String = "") -> String:
	if scene_path != "":
		return scene_path

	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return ""

	return tree.current_scene.scene_file_path


func has_bought_scene_health_potion(scene_path: String = "") -> bool:
	var purchase_key := get_scene_purchase_key(scene_path)
	if purchase_key == "":
		return false

	return bool(scene_health_potion_purchases.get(purchase_key, false))


func mark_scene_health_potion_bought(scene_path: String = "") -> void:
	var purchase_key := get_scene_purchase_key(scene_path)
	if purchase_key == "":
		return

	scene_health_potion_purchases[purchase_key] = true
	save_game()


func clear_scene_health_potion_purchase(scene_path: String = "") -> void:
	var purchase_key := get_scene_purchase_key(scene_path)
	if purchase_key == "":
		return

	scene_health_potion_purchases.erase(purchase_key)
	scene_rough_charm_purchases.erase(purchase_key)


func has_bought_scene_rough_charm(scene_path: String = "") -> bool:
	var purchase_key := get_scene_purchase_key(scene_path)
	if purchase_key == "":
		return false

	return bool(scene_rough_charm_purchases.get(purchase_key, false))


func mark_scene_rough_charm_bought(scene_path: String = "") -> void:
	var purchase_key := get_scene_purchase_key(scene_path)
	if purchase_key == "":
		return

	scene_rough_charm_purchases[purchase_key] = true
	save_game()


func refill_health_potions() -> void:
	var current_amount := get_health_potion_count()
	inventory[HEALTH_POSITION_ITEM] = mini(maxi(current_amount, STARTING_HEALTH_POTIONS), MAX_HEALTH_POTIONS)
	inventory.erase(HEALTH_POTION_ITEM)
	inventory_changed.emit(inventory)
	health_potions_changed.emit(get_health_potion_count())


func use_health_potion() -> bool:
	var amount := get_health_potion_count()
	if amount <= 0:
		return false

	if int(inventory.get(HEALTH_POSITION_ITEM, 0)) > 0:
		var health_position_amount := int(inventory.get(HEALTH_POSITION_ITEM, 0)) - 1
		if health_position_amount <= 0:
			inventory.erase(HEALTH_POSITION_ITEM)
		else:
			inventory[HEALTH_POSITION_ITEM] = health_position_amount
	else:
		var health_potion_amount := int(inventory.get(HEALTH_POTION_ITEM, 0)) - 1
		if health_potion_amount <= 0:
			inventory.erase(HEALTH_POTION_ITEM)
		else:
			inventory[HEALTH_POTION_ITEM] = health_potion_amount

	amount = get_health_potion_count()

	inventory_changed.emit(inventory)
	health_potions_changed.emit(amount)
	save_game()
	return true


func get_item_display_name(item_name: String) -> String:
	var localized_name: String = _get_localized_item_text(item_name, true)
	if localized_name != "":
		return localized_name
	var data: Dictionary = item_database.get(item_name, {})
	return _tr_raw(String(data.get("display_name", item_name)))


func get_item_description(item_name: String) -> String:
	var localized_description: String = _get_localized_item_text(item_name, false)
	if localized_description != "":
		return localized_description
	var data: Dictionary = item_database.get(item_name, {})
	return _tr_raw(String(data.get("description", _t("ITEM_UNKNOWN_DESC"))))


func set_respawn_position(position: Vector2) -> void:
	saved_respawn_position = position
	has_saved_respawn = true


func _get_localized_item_text(item_name: String, display_name: bool) -> String:
	var key: String = ""
	if is_health_potion_item(item_name):
		key = "ITEM_HEALTH_POTION" if display_name else "ITEM_HEALTH_POTION_DESC"
	elif item_name == STARTER_ITEM:
		key = "ITEM_TRAVELER_NOTE" if display_name else "ITEM_TRAVELER_NOTE_DESC"
	elif is_rough_charm_item(item_name):
		key = "ITEM_ROUGH_CHARM" if display_name else "ITEM_ROUGH_CHARM_DESC"
	elif item_name == "生命碎片":
		key = "ITEM_LIFE_FRAGMENT" if display_name else "ITEM_LIFE_FRAGMENT_DESC"
	elif item_name == "破舊地圖":
		key = "ITEM_OLD_MAP" if display_name else "ITEM_OLD_MAP_DESC"

	return "" if key == "" else _t(key)


func _t(key: String) -> String:
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _tr_raw(text: String) -> String:
	var localization: Node = get_node_or_null("/root/Localization")
	if localization != null and localization.has_method("translate_raw"):
		return String(localization.call("translate_raw", text))
	return text


func get_respawn_position(default_position: Vector2) -> Vector2:
	if has_pending_spawn:
		has_pending_spawn = false
		return pending_spawn_position
	if not demo_start_fresh and load_save_on_start and has_saved_respawn:
		return saved_respawn_position
	return default_position


func set_pending_spawn_position(position: Vector2) -> void:
	pending_spawn_position = position
	has_pending_spawn = true
	pending_spawn_marker_name = ""


func set_pending_spawn_marker(marker_name: String) -> void:
	pending_spawn_marker_name = marker_name
	has_pending_spawn = false


func consume_pending_spawn_marker() -> String:
	var marker_name := pending_spawn_marker_name
	pending_spawn_marker_name = ""
	return marker_name


func register_map_room(scene_path: String, room_id: String, display_name: String, map_rect: Rect2, world_rect := Rect2()) -> void:
	if scene_path == "" or room_id == "":
		return

	if not map_rooms.has(scene_path):
		map_rooms[scene_path] = {}

	map_rooms[scene_path][room_id] = {
		"display_name": display_name,
		"rect": map_rect,
		"world_rect": world_rect,
	}


func set_current_map_room(scene_path: String, room_id: String) -> void:
	if scene_path == "" or room_id == "":
		return

	if current_map_scene == scene_path and current_map_room == room_id:
		return

	current_map_scene = scene_path
	current_map_room = room_id
	if not visited_rooms.has(scene_path):
		visited_rooms[scene_path] = {}
	visited_rooms[scene_path][room_id] = true
	map_room_changed.emit(scene_path, room_id)


func set_equipped_skills(skill_ids: Array[String], skill_icons: Array[String]) -> void:
	equipped_skill_ids = _normalize_skill_array(skill_ids)
	equipped_skill_icons = _normalize_skill_array(skill_icons)
	equipped_skills_changed.emit(equipped_skill_icons)


func set_equipped_skill_icons(skill_icons: Array[String]) -> void:
	set_equipped_skills(equipped_skill_ids, skill_icons)


func get_active_skill_icons() -> Array[String]:
	return _get_active_pair(equipped_skill_icons)


func get_active_skill_ids() -> Array[String]:
	return _get_active_pair(equipped_skill_ids)


func set_active_skill_group(_group_index: int) -> void:
	var next_group := 0
	if active_skill_group == next_group:
		return
	active_skill_group = next_group
	active_skill_group_changed.emit(active_skill_group)


func toggle_active_skill_group() -> void:
	set_active_skill_group(1 - active_skill_group)


func add_ultimate_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	var next_charge := clampf(ultimate_charge + amount, 0.0, ultimate_charge_max)
	if is_equal_approx(next_charge, ultimate_charge):
		return
	ultimate_charge = next_charge
	ultimate_charge_changed.emit(ultimate_charge, ultimate_charge_max)


func is_ultimate_ready() -> bool:
	return ultimate_charge >= ultimate_charge_max


func consume_ultimate_charge() -> bool:
	if not is_ultimate_ready():
		return false
	ultimate_charge = 0.0
	ultimate_charge_changed.emit(ultimate_charge, ultimate_charge_max)
	return true


func _normalize_skill_array(values: Array[String]) -> Array[String]:
	var normalized: Array[String] = []
	for i in range(4):
		normalized.append(String(values[i]) if i < values.size() else "")
	return normalized


func _get_active_pair(values: Array[String]) -> Array[String]:
	var normalized := _normalize_skill_array(values)
	var start_index := active_skill_group * 2
	return [normalized[start_index], normalized[start_index + 1]]


func get_map_rooms(scene_path: String) -> Dictionary:
	return map_rooms.get(scene_path, {})


func is_room_visited(scene_path: String, room_id: String) -> bool:
	return bool(visited_rooms.get(scene_path, {}).get(room_id, false))


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "currency", currency)
	config.set_value("player", "inventory", inventory)
	config.set_value("player", "scene_health_potion_purchases", scene_health_potion_purchases)
	config.set_value("player", "scene_rough_charm_purchases", scene_rough_charm_purchases)
	config.set_value("player", "has_respawn", has_saved_respawn)
	config.set_value("player", "respawn_position", saved_respawn_position)
	var scene_path := _get_current_scene_path()
	var player_position := _get_current_player_position()
	config.set_value("save", "current_scene", scene_path)
	config.set_value("save", "position_x", player_position.x)
	config.set_value("save", "position_y", player_position.y)
	config.set_value("save", "coins", currency)
	config.set_value("save", "saved_at", _get_save_timestamp())
	config.set_value("save", "preview_scene_name", get_scene_display_name(scene_path))
	config.save(SAVE_PATH)


func save_continue_scene(scene_path: String, player_position := Vector2.ZERO, has_player_position := false, spawn_marker_name := "") -> void:
	if scene_path == "":
		return

	continue_scene_path = scene_path
	continue_player_position = player_position
	has_continue_player_position = has_player_position
	continue_spawn_marker_name = spawn_marker_name
	has_continue_spawn_marker = spawn_marker_name != ""
	var config := ConfigFile.new()
	config.set_value("continue", "scene_path", continue_scene_path)
	config.set_value("continue", "has_player_position", has_continue_player_position)
	config.set_value("continue", "player_position", continue_player_position)
	config.set_value("continue", "position_x", continue_player_position.x)
	config.set_value("continue", "position_y", continue_player_position.y)
	config.set_value("continue", "has_spawn_marker", has_continue_spawn_marker)
	config.set_value("continue", "spawn_marker_name", continue_spawn_marker_name)
	config.set_value("continue", "coins", currency)
	config.set_value("continue", "saved_at", _get_save_timestamp())
	config.set_value("continue", "preview_scene_name", get_scene_display_name(continue_scene_path))
	config.save(CONTINUE_SCENE_SAVE_PATH)


func load_continue_scene_path() -> String:
	var config := ConfigFile.new()
	var error := config.load(CONTINUE_SCENE_SAVE_PATH)
	if error != OK:
		return DEFAULT_START_SCENE

	continue_scene_path = String(config.get_value("continue", "scene_path", DEFAULT_START_SCENE))
	has_continue_player_position = bool(config.get_value("continue", "has_player_position", false))
	has_continue_spawn_marker = bool(config.get_value("continue", "has_spawn_marker", false))
	continue_spawn_marker_name = String(config.get_value("continue", "spawn_marker_name", ""))
	var loaded_position: Variant = config.get_value("continue", "player_position", Vector2.ZERO)
	if loaded_position is Vector2:
		continue_player_position = loaded_position
	else:
		has_continue_player_position = false

	if continue_scene_path == "":
		continue_scene_path = DEFAULT_START_SCENE
	return continue_scene_path


func prepare_continue_scene() -> String:
	var scene_path := load_continue_scene_path()
	if has_continue_spawn_marker and continue_spawn_marker_name != "":
		set_pending_spawn_marker(continue_spawn_marker_name)
	elif has_continue_player_position:
		set_pending_spawn_position(continue_player_position)
	return scene_path


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH)


func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}

	var info := {
		"current_scene": DEFAULT_START_SCENE,
		"position_x": 0.0,
		"position_y": 0.0,
		"coins": currency,
		"saved_at": "",
		"preview_image": "",
		"preview_scene_name": get_scene_display_name(DEFAULT_START_SCENE),
	}

	if FileAccess.file_exists(SAVE_PATH):
		var save_config := ConfigFile.new()
		if save_config.load(SAVE_PATH) == OK:
			var scene_path := String(save_config.get_value("save", "current_scene", info["current_scene"]))
			info["current_scene"] = scene_path
			info["position_x"] = float(save_config.get_value("save", "position_x", info["position_x"]))
			info["position_y"] = float(save_config.get_value("save", "position_y", info["position_y"]))
			info["coins"] = int(save_config.get_value("save", "coins", save_config.get_value("player", "currency", currency)))
			info["saved_at"] = String(save_config.get_value("save", "saved_at", info["saved_at"]))
			info["preview_scene_name"] = String(save_config.get_value("save", "preview_scene_name", get_scene_display_name(scene_path)))

	if FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH):
		var continue_config := ConfigFile.new()
		if continue_config.load(CONTINUE_SCENE_SAVE_PATH) == OK:
			var continue_scene := String(continue_config.get_value("continue", "scene_path", info["current_scene"]))
			var loaded_position: Variant = continue_config.get_value("continue", "player_position", Vector2(float(info["position_x"]), float(info["position_y"])))
			info["current_scene"] = continue_scene
			if loaded_position is Vector2:
				info["position_x"] = loaded_position.x
				info["position_y"] = loaded_position.y
			else:
				info["position_x"] = float(continue_config.get_value("continue", "position_x", info["position_x"]))
				info["position_y"] = float(continue_config.get_value("continue", "position_y", info["position_y"]))
			info["coins"] = int(continue_config.get_value("continue", "coins", info["coins"]))
			info["saved_at"] = String(continue_config.get_value("continue", "saved_at", info["saved_at"]))
			info["preview_scene_name"] = String(continue_config.get_value("continue", "preview_scene_name", get_scene_display_name(continue_scene)))

	if String(info["saved_at"]) == "":
		var modified_path := CONTINUE_SCENE_SAVE_PATH if FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH) else SAVE_PATH
		info["saved_at"] = _get_file_modified_timestamp(modified_path)
	if String(info["saved_at"]) == "":
		info["saved_at"] = "未知"
	if String(info["preview_scene_name"]) == "":
		info["preview_scene_name"] = get_scene_display_name(String(info["current_scene"]))
	return info


func clear_save_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH):
		DirAccess.remove_absolute(CONTINUE_SCENE_SAVE_PATH)
	clear_continue_scene()


func start_new_game() -> String:
	clear_save_file()
	reset_demo_state()
	clear_continue_scene()
	set_input_locked(false)
	return DEFAULT_START_SCENE


func continue_game() -> String:
	load_game()
	set_input_locked(false)
	if not has_continue_scene() and FileAccess.file_exists(SAVE_PATH):
		return _prepare_save_file_scene()
	return prepare_continue_scene()


func has_continue_scene() -> bool:
	return FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH)


func clear_continue_scene() -> void:
	continue_scene_path = DEFAULT_START_SCENE
	continue_player_position = Vector2.ZERO
	has_continue_player_position = false
	continue_spawn_marker_name = ""
	has_continue_spawn_marker = false
	has_pending_spawn = false
	pending_spawn_position = Vector2.ZERO
	pending_spawn_marker_name = ""
	if FileAccess.file_exists(CONTINUE_SCENE_SAVE_PATH):
		DirAccess.remove_absolute(CONTINUE_SCENE_SAVE_PATH)


func load_game() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return

	currency = int(config.get_value("player", "currency", currency))
	var loaded_inventory: Variant = config.get_value("player", "inventory", inventory)
	if loaded_inventory is Dictionary:
		inventory = loaded_inventory
		merge_health_potion_items()

	var loaded_scene_health_potion_purchases: Variant = config.get_value("player", "scene_health_potion_purchases", scene_health_potion_purchases)
	if loaded_scene_health_potion_purchases is Dictionary:
		scene_health_potion_purchases = loaded_scene_health_potion_purchases

	var loaded_scene_rough_charm_purchases: Variant = config.get_value("player", "scene_rough_charm_purchases", scene_rough_charm_purchases)
	if loaded_scene_rough_charm_purchases is Dictionary:
		scene_rough_charm_purchases = loaded_scene_rough_charm_purchases

	has_saved_respawn = bool(config.get_value("player", "has_respawn", false))
	var loaded_position: Variant = config.get_value("player", "respawn_position", Vector2.ZERO)
	if loaded_position is Vector2:
		saved_respawn_position = loaded_position


func get_scene_display_name(scene_path: String) -> String:
	match scene_path:
		"res://demo/scenes/levels/demo_level_1.tscn":
			return "深海洞窟"
		"res://demo/scenes/levels/demo_water.tscn":
			return "水中通道"
		"res://demo/scenes/levels/demo_boss.tscn":
			return "Boss 房間"
		"res://demo/scenes/levels/demo_boss_phase_2.tscn":
			return "Boss 第二階段"
		_:
			if scene_path == "":
				return "未知地點"
			var file_name := scene_path.get_file().get_basename()
			return file_name.replace("_", " ")


func _get_current_scene_path() -> String:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return continue_scene_path if continue_scene_path != "" else DEFAULT_START_SCENE
	var scene_path := tree.current_scene.scene_file_path
	return scene_path if scene_path != "" else DEFAULT_START_SCENE


func _get_current_player_position() -> Vector2:
	var tree := get_tree()
	if tree != null:
		var player := tree.get_first_node_in_group("player")
		if player is Node2D:
			return player.global_position
	if has_saved_respawn:
		return saved_respawn_position
	return continue_player_position


func _get_save_timestamp() -> String:
	return _format_datetime_dict(Time.get_datetime_dict_from_system())


func _get_file_modified_timestamp(path: String) -> String:
	if path == "" or not FileAccess.file_exists(path):
		return ""
	var unix_time := int(FileAccess.get_modified_time(path))
	if unix_time <= 0:
		return ""
	return _format_datetime_dict(Time.get_datetime_dict_from_unix_time(unix_time))


func _format_datetime_dict(datetime: Dictionary) -> String:
	return "%04d/%02d/%02d %02d:%02d" % [
		int(datetime.get("year", 0)),
		int(datetime.get("month", 0)),
		int(datetime.get("day", 0)),
		int(datetime.get("hour", 0)),
		int(datetime.get("minute", 0)),
	]


func _prepare_save_file_scene() -> String:
	var save_info := get_save_info()
	if save_info.is_empty():
		return DEFAULT_START_SCENE

	var scene_path := String(save_info.get("current_scene", DEFAULT_START_SCENE))
	if scene_path == "":
		scene_path = DEFAULT_START_SCENE
	var position := Vector2(
		float(save_info.get("position_x", 0.0)),
		float(save_info.get("position_y", 0.0))
	)
	if position != Vector2.ZERO:
		set_pending_spawn_position(position)
	return scene_path
