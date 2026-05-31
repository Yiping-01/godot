extends CanvasLayer

const POTION_TEXTURE := preload("res://demo/assets/art/legacy/some/Health_Potion.png")
const ITEM_TEXTURE := preload("res://demo/assets/hollow_import/effects/glow_bug_01.png")
const NOTE_TEXTURE := preload("res://demo/assets/art/legacy/useicon_white.png")
const SKILL_TEXTURE := preload("res://demo/assets/art/legacy/player/attack_far/far_1.png")
const MAP_DRAW_CANVAS_SCRIPT := preload("res://demo/scripts/map_draw_canvas.gd")
const DEMO_MENU_UI_ART := preload("res://demo/scripts/demo_menu_ui_art.gd")
const INVENTORY_TAB_KEYS := ["INV_TAB_BAG", "INV_TAB_SKILLS", "INV_TAB_MAP"]
const INVENTORY_CATEGORY_KEYS := ["INV_CAT_ALL", "INV_CAT_CONSUMABLE", "INV_CAT_MATERIAL", "INV_CAT_IMPORTANT"]
const GRID_SLOT_COUNT := 40
const EQUIPPED_SKILL_SLOT_COUNT := 4
const DEMO_UI_FONT_PATH := "res://demo/assets/hollow_import/fonts/NotoSerifCJKsc-Regular.otf"
const DEMO_TITLE_FONT_PATH := "res://demo/assets/hollow_import/fonts/TrajanPro-Regular.otf"
const SKILL_LIBRARY := [
	{
		"id": "water_dash",
		"name_key": "INV_SKILL_WATER_DASH",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WATER_DASH_DESC",
		"texture": "res://demo/assets/art/legacy/player/attack_far/far_1.png",
		"cooldown": "常駐",
	},
	{
		"id": "wall_burst",
		"name_key": "INV_SKILL_WALL_BURST",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WALL_BURST_DESC",
		"texture": "res://demo/assets/art/legacy/player/attack_far/far_2.png",
		"cooldown": "常駐",
	},
	{
		"id": "water_shot",
		"name_key": "INV_SKILL_WATER_SHOT",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_WATER_SHOT_DESC",
		"texture": "res://demo/assets/art/legacy/player/attack_far/far_3.png",
		"cooldown": "3 秒",
	},
	{
		"id": "quick_map",
		"name_key": "INV_SKILL_QUICK_MAP",
		"type_key": "INV_CAT_SKILL",
		"description_key": "INV_SKILL_QUICK_MAP_DESC",
		"texture": "res://demo/assets/art/legacy/player/attack_far/far_4.png",
		"cooldown": "常駐",
	},
]

@onready var prompt_label: Label = $PromptLabel
@onready var toast_label: Label = $ToastLabel
@onready var hud_currency_label: Label = $CurrencyLabel
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var dialogue_corner_icon: TextureRect = $DialoguePanel/CornerIcon
@onready var dialogue_vbox: VBoxContainer = $DialoguePanel/VBoxContainer
@onready var dialogue_name_label: Label = $DialoguePanel/VBoxContainer/NameLabel
@onready var dialogue_text_label: Label = $DialoguePanel/VBoxContainer/DialogueLabel
@onready var dialogue_hint_label: Label = $DialoguePanel/VBoxContainer/HintLabel
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_title_label: Label = $InventoryPanel/VBoxContainer/TitleLabel
@onready var inventory_currency_label: Label = $InventoryPanel/VBoxContainer/CurrencyLabel
@onready var shop_panel: Panel = $ShopPanel
@onready var shop_corner_icon: TextureRect = $ShopPanel/CornerIcon
@onready var shop_vbox: VBoxContainer = $ShopPanel/VBoxContainer
@onready var shop_title_label: Label = $ShopPanel/VBoxContainer/TitleLabel
@onready var shop_currency_label: Label = $ShopPanel/VBoxContainer/CurrencyLabel
@onready var shop_item_buttons: Array[Button] = [
	$ShopPanel/VBoxContainer/ShopItem0,
	$ShopPanel/VBoxContainer/ShopItem1,
	$ShopPanel/VBoxContainer/ShopItem2,
]
@onready var shop_close_hint_label: Label = $ShopPanel/VBoxContainer/CloseHintLabel
@onready var map_panel: Panel = $MapPanel
@onready var map_corner_icon: TextureRect = $MapPanel/CornerIcon
@onready var map_vbox: VBoxContainer = $MapPanel/VBoxContainer
@onready var map_title_label: Label = $MapPanel/VBoxContainer/TitleLabel
@onready var map_canvas: Control = $MapPanel/VBoxContainer/MapCanvas
@onready var map_hint_label: Label = $MapPanel/VBoxContainer/HintLabel
@onready var area_title_panel: Panel = $AreaTitlePanel
@onready var area_subtitle_label: Label = $AreaTitlePanel/VBoxContainer/SubTitleLabel
@onready var area_main_title_label: Label = $AreaTitlePanel/VBoxContainer/MainTitleLabel
@onready var fade_rect: ColorRect = $FadeRect

var active_npc: Node
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var shop_items: Array[Dictionary] = []
var toast_tween: Tween
var area_title_tween: Tween
var fade_tween: Tween
var coin_tween: Tween
var coin_gain_label: Label
var world_prompt_sources: Dictionary = {}
var map_display_mode := 0
var inventory_profile_label: Label
var inventory_grid_scroll: ScrollContainer
var inventory_grid: GridContainer
var inventory_detail_icon: TextureRect
var inventory_detail_title: Label
var inventory_detail_type: Label
var inventory_detail_description: Label
var inventory_skill_meta_label: Label
var inventory_profile_panel: VBoxContainer
var inventory_profile_title_label: Label
var inventory_equipped_title_label: Label
var inventory_equipped_grid: HBoxContainer
var inventory_skill_separator: ColorRect
var inventory_hint_label: Label
var inventory_category_row: HBoxContainer
var inventory_category_buttons: Array[Button] = []
var inventory_tab_buttons: Array[Button] = []
var inventory_entry_buttons: Array[Button] = []
var inventory_current_entries: Array[Dictionary] = []
var equipped_skill_slots: Array[Button] = []
var equipped_skills: Array[Dictionary] = []
var selected_skill_for_equip: Dictionary = {}
var selected_equip_slot_index := -1
var selected_inventory_grid_index := -1
var selected_inventory_category_focus_index := -1
var selected_inventory_tab_key := "INV_TAB_BAG"
var selected_inventory_category_key := "INV_CAT_ALL"
var last_currency_amount := 0
var current_prompt_text := ""
var current_toast_text := ""
var selected_shop_index := -1

const MAP_MODE_CLOSED := 0
const MAP_MODE_MINI := 1
const MAP_MODE_FULL := 2
const MAP_CANVAS_FULL_SIZE := Vector2(980.0, 560.0)
const MAP_CANVAS_MINI_SIZE := Vector2(292.0, 186.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_ui")
	_apply_demo_ui_fonts()
	if map_canvas.get_script() == null:
		map_canvas.set_script(MAP_DRAW_CANVAS_SCRIPT)
	_build_inventory_window()
	_apply_demo_ui_fonts()
	_reset_equipped_skills()
	_configure_demo_coin_hud()
	last_currency_amount = GameState.currency

	prompt_label.hide()
	toast_label.hide()
	dialogue_panel.hide()
	inventory_panel.hide()
	shop_panel.hide()
	map_panel.hide()

	area_title_panel.modulate.a = 0.0
	area_title_panel.hide()

	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	GameState.currency_changed.connect(_on_currency_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.first_item_obtained.connect(_on_first_item_obtained)
	GameState.map_room_changed.connect(_on_map_room_changed)
	var localization: Node = _get_localization()
	if localization != null:
		localization.connect("language_changed", Callable(self, "_refresh_localized_texts"))
	var input_settings := get_node_or_null("/root/InputSettings")
	if input_settings != null:
		input_settings.connect("controls_changed", Callable(self, "_on_controls_changed"))

	for i in range(shop_item_buttons.size()):
		shop_item_buttons[i].pressed.connect(_on_shop_item_pressed.bind(i))
		shop_item_buttons[i].focus_mode = Control.FOCUS_ALL
		shop_item_buttons[i].add_theme_stylebox_override("focus", _make_style(Color(0.08, 0.12, 0.13, 0.96), Color(1.0, 0.8, 0.35, 0.94), 2, 4))

	_on_currency_changed(GameState.currency)
	_on_inventory_changed(GameState.inventory)
	_refresh_localized_texts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if inventory_panel.visible or shop_panel.visible or dialogue_panel.visible or map_panel.visible:
			close_all_windows()
		elif not GameState.input_locked:
			toggle_inventory()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("map"):
		if inventory_panel.visible or shop_panel.visible or dialogue_panel.visible:
			close_all_windows()
		elif map_panel.visible or not GameState.input_locked:
			toggle_map()
		get_viewport().set_input_as_handled()

	if inventory_panel.visible and _handle_inventory_navigation(event):
		get_viewport().set_input_as_handled()
		return

	if shop_panel.visible and _handle_shop_navigation(event):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		close_all_windows()
		get_viewport().set_input_as_handled()

	if (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")) and dialogue_panel.visible:
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func show_prompt(text: String) -> void:
	if dialogue_panel.visible or shop_panel.visible or inventory_panel.visible or map_panel.visible:
		return

	current_prompt_text = text
	prompt_label.text = _format_action_text(_tr_raw(current_prompt_text))
	_style_hint_label(prompt_label, false)
	var viewport_size := get_viewport().get_visible_rect().size
	_set_control_rect(prompt_label, Rect2(Vector2((viewport_size.x - 460.0) * 0.5, viewport_size.y - 96.0), Vector2(460.0, 38.0)))
	prompt_label.show()


func hide_prompt() -> void:
	prompt_label.hide()


func open_npc_dialogue(npc: Node) -> void:
	if npc == null:
		return

	_hide_area_title_for_window()
	active_npc = npc
	dialogue_lines.assign(npc.dialogue_lines)
	dialogue_index = 0

	hide_prompt()
	GameState.set_input_locked(true)

	dialogue_name_label.text = _tr_raw(npc.display_name)
	_apply_dialogue_layout()
	dialogue_panel.show()
	_show_dialogue_line()


func toggle_inventory() -> void:
	if inventory_panel.visible:
		close_all_windows()
		return

	hide_prompt()
	_hide_area_title_for_window()
	GameState.set_input_locked(true)
	_update_inventory_text(GameState.inventory)
	inventory_panel.show()


func toggle_map() -> void:
	if map_display_mode == MAP_MODE_CLOSED:
		_show_mini_map()
	elif map_display_mode == MAP_MODE_MINI:
		_show_full_map()
	else:
		close_all_windows()


func _show_mini_map() -> void:
	hide_prompt()
	_hide_area_title_for_window()
	GameState.set_input_locked(false)
	_apply_map_layout(MAP_MODE_MINI)
	_rebuild_map()
	map_panel.show()


func _show_full_map() -> void:
	hide_prompt()
	_hide_area_title_for_window()
	GameState.set_input_locked(false)
	_apply_map_layout(MAP_MODE_FULL)
	_rebuild_map()
	map_panel.show()


func close_all_windows() -> void:
	dialogue_panel.hide()
	inventory_panel.hide()
	shop_panel.hide()
	map_panel.hide()
	_apply_map_layout(MAP_MODE_CLOSED)

	active_npc = null
	selected_shop_index = -1
	GameState.set_input_locked(false)


func has_open_window() -> bool:
	return dialogue_panel.visible or inventory_panel.visible or shop_panel.visible or map_panel.visible


func has_prompt() -> bool:
	return prompt_label.visible or not world_prompt_sources.is_empty()


func set_world_prompt_active(source: Object, active: bool) -> void:
	if source == null:
		return
	var source_id := source.get_instance_id()
	if active:
		world_prompt_sources[source_id] = true
	else:
		world_prompt_sources.erase(source_id)


func show_area_title(main_title: String, sub_title: String) -> void:
	area_main_title_label.text = _tr_raw(main_title)
	area_subtitle_label.text = _tr_raw(sub_title)
	area_title_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	area_title_panel.offset_left = -320.0
	area_title_panel.offset_top = 88.0
	area_title_panel.offset_right = 320.0
	area_title_panel.offset_bottom = 164.0
	area_title_panel.add_theme_stylebox_override("panel", _make_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0, 0))
	area_main_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_title_panel.show()

	if area_title_tween != null:
		area_title_tween.kill()

	area_title_panel.modulate.a = 0.0
	area_title_tween = create_tween()
	area_title_tween.tween_property(area_title_panel, "modulate:a", 1.0, 0.45)
	area_title_tween.tween_interval(2.0)
	area_title_tween.tween_property(area_title_panel, "modulate:a", 0.0, 0.55)
	area_title_tween.tween_callback(_hide_instance_id.bind(area_title_panel.get_instance_id()))


func _hide_area_title_for_window() -> void:
	if area_title_tween != null:
		area_title_tween.kill()
	area_title_panel.hide()


func show_toast(text: String, duration: float = 2.0) -> void:
	current_toast_text = text
	toast_label.text = _format_action_text(_tr_raw(current_toast_text))
	_style_hint_label(toast_label, true)
	var viewport_size := get_viewport().get_visible_rect().size
	var toast_width := minf(1320.0, maxf(560.0, viewport_size.x - 240.0))
	var toast_height := 72.0
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.clip_text = true
	_set_control_rect(toast_label, Rect2(Vector2((viewport_size.x - toast_width) * 0.5, 72.0), Vector2(toast_width, toast_height)))
	toast_label.show()

	if toast_tween != null:
		toast_tween.kill()

	toast_label.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)
	toast_tween.tween_callback(_hide_instance_id.bind(toast_label.get_instance_id()))


func show_coin_gain(amount: int) -> void:
	if hud_currency_label == null:
		return

	if coin_tween != null:
		coin_tween.kill()

	_configure_demo_coin_hud()
	hud_currency_label.text = "寶特瓶：%d" % last_currency_amount
	hud_currency_label.show()
	hud_currency_label.modulate = Color(1.0, 0.92, 0.64, 1.0)
	hud_currency_label.scale = Vector2.ONE
	_show_coin_gain_pop(amount)
	coin_tween = create_tween()
	coin_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	coin_tween.tween_property(hud_currency_label, "scale", Vector2.ONE * 1.14, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	coin_tween.parallel().tween_method(_set_coin_counter_text, last_currency_amount, GameState.currency, 0.24)
	coin_tween.tween_property(hud_currency_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	coin_tween.tween_interval(1.35)
	coin_tween.tween_property(hud_currency_label, "modulate:a", 0.0, 0.45)
	coin_tween.tween_callback(_hide_instance_id.bind(hud_currency_label.get_instance_id()))
	last_currency_amount = GameState.currency


func show_tutorial(text: String, duration: float = 2.8) -> void:
	show_toast(text, duration)

func is_area_title_visible() -> bool:
	return area_title_panel.visible



func hide_tutorial() -> void:
	if toast_tween != null:
		toast_tween.kill()

	toast_label.hide()


func fade_out(duration: float = 0.25) -> void:
	await _fade_to(1.0, duration)


func fade_in(duration: float = 0.25) -> void:
	await _fade_to(0.0, duration)


func _fade_to(alpha: float, duration: float) -> void:
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_rect, "modulate:a", alpha, duration)

	await fade_tween.finished


func _show_dialogue_line() -> void:
	dialogue_text_label.text = "..." if dialogue_lines.is_empty() else _format_action_text(_tr_raw(dialogue_lines[dialogue_index]))

	var can_open_shop: bool = active_npc != null and active_npc.opens_shop and dialogue_index >= dialogue_lines.size() - 1

	if can_open_shop:
		dialogue_hint_label.text = _format_action_text(_t("DIALOGUE_SHOP_HINT"))
	else:
		dialogue_hint_label.text = _format_action_text(_t("DIALOGUE_NEXT_HINT"))


func _advance_dialogue() -> void:
	if active_npc == null:
		close_all_windows()
		return

	if dialogue_index < dialogue_lines.size() - 1:
		dialogue_index += 1
		_show_dialogue_line()
		return

	if active_npc.opens_shop:
		_open_shop(active_npc)
	else:
		close_all_windows()


func _open_shop(npc: Node) -> void:
	dialogue_panel.hide()

	if npc.has_method("get_shop_items"):
		shop_items.assign(npc.get_shop_items())
	else:
		shop_items.assign(npc.shop_items)
	shop_title_label.text = _t("SHOP_TITLE") % _tr_raw(npc.display_name)

	_apply_shop_layout()
	shop_panel.show()

	GameState.has_shown_inventory_tutorial = true
	show_toast(_t("SHOP_INVENTORY_HINT"), 3.0)

	_update_shop()
	_focus_first_available_shop_item()


func _update_shop() -> void:
	shop_currency_label.text = _t("CURRENCY_AMOUNT") % GameState.currency

	for i in range(shop_item_buttons.size()):
		var button := shop_item_buttons[i]

		if i >= shop_items.size():
			button.hide()
			continue

		var item := shop_items[i]
		var item_name := String(item["name"])
		var price := int(item["price"])
		var description := String(item["description"])
		var owned := GameState.has_item(item_name)
		var status_text: String = _t("SHOP_OWNED") if owned else ""
		if GameState.is_health_potion_item(item_name):
			owned = GameState.has_bought_scene_health_potion()
			if not GameState.can_add_health_potion():
				owned = true
				status_text = _t("SHOP_LIMIT")
			elif owned:
				status_text = _t("SHOP_OWNED")
		elif GameState.is_rough_charm_item(item_name):
			owned = GameState.has_bought_scene_rough_charm()
			status_text = _t("SHOP_OWNED") if owned else ""

		button.show()
		button.disabled = owned
		button.text = _t("SHOP_ITEM_LINE") % [
			GameState.get_item_display_name(item_name),
			price,
			status_text,
			_tr_raw(description),
		]

	shop_close_hint_label.text = _format_action_text(_t("SHOP_HINT"))


func _handle_shop_navigation(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if event.is_action_pressed("ui_up"):
		_focus_shop_item(-1)
		return true
	if event.is_action_pressed("ui_down"):
		_focus_shop_item(1)
		return true
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if selected_shop_index >= 0:
			_on_shop_item_pressed(selected_shop_index)
		return true
	return false


func _focus_first_available_shop_item() -> void:
	selected_shop_index = -1
	for i in range(shop_item_buttons.size()):
		var button := shop_item_buttons[i]
		if button.visible and not button.disabled:
			selected_shop_index = i
			button.grab_focus()
			return
	for i in range(shop_item_buttons.size()):
		var button := shop_item_buttons[i]
		if button.visible:
			selected_shop_index = i
			button.grab_focus()
			return


func _focus_shop_item(direction: int) -> void:
	if shop_item_buttons.is_empty():
		return
	var index := selected_shop_index
	for _step in range(shop_item_buttons.size()):
		index = wrapi(index + direction, 0, shop_item_buttons.size())
		var button := shop_item_buttons[index]
		if button.visible and not button.disabled:
			selected_shop_index = index
			button.grab_focus()
			return


func _rebuild_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()

	var scene_path := ""
	var scene := get_tree().current_scene

	if scene != null:
		scene_path = scene.scene_file_path

	var rooms := GameState.get_map_rooms(scene_path)

	map_title_label.text = _t("MAP_TITLE")
	map_hint_label.text = _format_action_text(_t("MAP_HINT"))
	if map_canvas.has_method("refresh"):
		map_canvas.set("compact", map_display_mode == MAP_MODE_MINI)
		map_canvas.call("refresh", scene_path)
		map_canvas.queue_redraw()
		return

	if rooms.is_empty():
		_add_map_empty_label()
		return

	for room_id in rooms.keys():
		var data: Dictionary = rooms[room_id]
		var room_rect: Rect2 = data.get("rect", Rect2(0, 0, 80, 52))
		var visited := GameState.is_room_visited(scene_path, String(room_id))
		var is_current := scene_path == GameState.current_map_scene and String(room_id) == GameState.current_map_room

		_add_map_room(
			String(room_id),
			_tr_raw(String(data.get("display_name", room_id))),
			room_rect,
			visited,
			is_current
		)

	_add_player_map_marker(rooms)


func _apply_map_layout(mode: int) -> void:
	map_display_mode = mode
	map_canvas.scale = Vector2.ONE
	map_canvas.clip_contents = true
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if mode == MAP_MODE_MINI:
		var viewport_size := get_viewport().get_visible_rect().size
		var panel_size := Vector2(320.0, 210.0)
		_set_control_rect(map_panel, Rect2(Vector2(viewport_size.x - panel_size.x - 54.0, 52.0), panel_size))
		_set_control_rect(map_vbox, Rect2(Vector2(14.0, 12.0), Vector2(292.0, 186.0)))
		map_corner_icon.hide()
		map_title_label.hide()
		map_hint_label.hide()
		map_canvas.custom_minimum_size = MAP_CANVAS_MINI_SIZE
		map_canvas.size = MAP_CANVAS_MINI_SIZE
		return

	_center_control(map_panel, Vector2(1080.0, 720.0))
	_set_control_rect(map_vbox, Rect2(Vector2(34.0, 28.0), Vector2(1012.0, 664.0)))
	map_corner_icon.hide()
	map_title_label.show()
	map_hint_label.show()
	map_canvas.custom_minimum_size = MAP_CANVAS_FULL_SIZE
	map_canvas.size = MAP_CANVAS_FULL_SIZE


func _set_control_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _center_control(control: Control, target_size: Vector2) -> void:
	var final_size := _fit_centered_size(target_size)
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = -final_size.x * 0.5
	control.offset_top = -final_size.y * 0.5
	control.offset_right = final_size.x * 0.5
	control.offset_bottom = final_size.y * 0.5


func _fit_centered_size(target_size: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		minf(target_size.x, maxf(minf(360.0, target_size.x), viewport_size.x - 80.0)),
		minf(target_size.y, maxf(minf(320.0, target_size.y), viewport_size.y - 80.0))
	)


func _apply_dialogue_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var target_size := Vector2(
		minf(960.0, maxf(560.0, viewport_size.x - 220.0)),
		minf(250.0, maxf(210.0, viewport_size.y - 180.0))
	)
	var panel_size := _fit_centered_size(target_size)
	_center_control(dialogue_panel, panel_size)
	_set_control_rect(dialogue_corner_icon, Rect2(Vector2(16.0, 16.0), Vector2(34.0, 34.0)))
	_set_control_rect(dialogue_vbox, Rect2(Vector2(66.0, 22.0), panel_size - Vector2(92.0, 44.0)))
	dialogue_text_label.custom_minimum_size = Vector2(0.0, maxf(92.0, panel_size.y - 138.0))
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _apply_shop_layout() -> void:
	var panel_size := _fit_centered_size(Vector2(620.0, 454.0))
	_center_control(shop_panel, panel_size)
	_set_control_rect(shop_corner_icon, Rect2(Vector2(panel_size.x - 52.0, 16.0), Vector2(32.0, 32.0)))
	_set_control_rect(shop_vbox, Rect2(Vector2(22.0, 18.0), panel_size - Vector2(44.0, 38.0)))


func _add_map_empty_label() -> void:
	var label := Label.new()
	label.text = _t("MAP_EMPTY")
	label.add_theme_font_size_override("font_size", 12 if map_display_mode == MAP_MODE_MINI else 18)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.clip_text = true
	label.position = Vector2(8, 8) if map_display_mode == MAP_MODE_MINI else Vector2(20, 20)
	label.size = Vector2(280, 70) if map_display_mode == MAP_MODE_MINI else Vector2(360, 40)

	map_canvas.add_child(label)


func _add_map_room(room_id: String, display_name: String, room_rect: Rect2, visited: bool, is_current: bool) -> void:
	var room := ColorRect.new()
	room.name = "MapRoom_%s" % room_id
	room.position = room_rect.position
	room.size = room_rect.size

	if visited:
		room.color = Color(0.18, 0.25, 0.30, 0.9)
	else:
		room.color = Color(0.07, 0.08, 0.10, 0.75)

	if is_current:
		room.color = Color(0.95, 0.72, 0.24, 0.95)

	map_canvas.add_child(room)

	var label := Label.new()
	label.text = display_name
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = room_rect.position
	label.size = room_rect.size

	map_canvas.add_child(label)

func _add_player_map_marker(rooms: Dictionary) -> void:
	if GameState.current_map_room == "":
		return

	if not rooms.has(GameState.current_map_room):
		return

	var player := get_tree().get_first_node_in_group("player")

	if not player is Node2D:
		return

	var data: Dictionary = rooms[GameState.current_map_room]
	var room_rect: Rect2 = data.get("rect", Rect2())
	var world_rect: Rect2 = data.get("world_rect", Rect2())

	if room_rect.size == Vector2.ZERO or world_rect.size == Vector2.ZERO:
		return

	var player_position: Vector2 = player.global_position

	var x_ratio := inverse_lerp(world_rect.position.x, world_rect.end.x, player_position.x)
	var y_ratio := inverse_lerp(world_rect.position.y, world_rect.end.y, player_position.y)

	x_ratio = clampf(x_ratio, 0.0, 1.0)
	y_ratio = clampf(y_ratio, 0.0, 1.0)

	var marker := ColorRect.new()
	marker.name = "PlayerMapMarker"
	marker.color = Color(0.15, 1.0, 0.95, 1.0)
	marker.size = Vector2(12, 12)
	marker.position = room_rect.position + Vector2(
		room_rect.size.x * x_ratio,
		room_rect.size.y * y_ratio
	) - marker.size * 0.5

	map_canvas.add_child(marker)


func _on_shop_item_pressed(index: int) -> void:
	if index >= shop_items.size():
		return

	var item := shop_items[index]
	var item_name := String(item["name"])
	var price := int(item["price"])
	var is_health_potion := GameState.is_health_potion_item(item_name)
	var is_rough_charm := GameState.is_rough_charm_item(item_name)
	var purchase_item_name := GameState.HEALTH_POSITION_ITEM if is_health_potion else item_name

	if is_health_potion and GameState.has_bought_scene_health_potion():
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(purchase_item_name))
		return

	if is_health_potion and not GameState.can_add_health_potion():
		show_toast(_t("SHOP_POTION_LIMIT"))
		return

	if is_rough_charm and GameState.has_bought_scene_rough_charm():
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(item_name))
		return

	if not is_health_potion and not is_rough_charm and GameState.has_item(item_name):
		show_toast(_t("SHOP_ALREADY_HAVE") % GameState.get_item_display_name(item_name))
		return

	if not GameState.spend_currency(price):
		show_toast(_t("SHOP_NOT_ENOUGH_MONEY"))
		return

	if is_health_potion:
		GameState.add_health_potions(1)
		GameState.mark_scene_health_potion_bought()
	elif is_rough_charm:
		GameState.add_item(item_name)
		GameState.mark_scene_rough_charm_bought()
	else:
		GameState.add_item(item_name)
	GameState.save_game()

	show_toast(_t("SHOP_GOT_ITEM") % GameState.get_item_display_name(purchase_item_name))
	_update_shop()
	_focus_first_available_shop_item()


func _on_currency_changed(amount: int) -> void:
	if inventory_currency_label != null:
		inventory_currency_label.text = _t("CURRENCY_AMOUNT") % amount
	if shop_currency_label != null:
		shop_currency_label.text = _t("CURRENCY_AMOUNT") % amount
	if amount > last_currency_amount:
		show_coin_gain(amount - last_currency_amount)
	else:
		last_currency_amount = amount


func _configure_demo_coin_hud() -> void:
	if hud_currency_label == null or not _is_demo_scene():
		return

	hud_currency_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hud_currency_label.offset_left = -202.0
	hud_currency_label.offset_top = -132.0
	hud_currency_label.offset_right = -28.0
	hud_currency_label.offset_bottom = -92.0
	hud_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_currency_label.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.018, 0.014, 0.78), Color(0.58, 0.50, 0.34, 0.58), 1, 3))
	hud_currency_label.add_theme_font_size_override("font_size", 20)
	hud_currency_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.44, 1.0))
	_set_coin_counter_text(GameState.currency)
	hud_currency_label.hide()


func _set_coin_counter_text(value: float) -> void:
	if hud_currency_label != null:
		hud_currency_label.text = "寶特瓶：%d" % roundi(value)


func _show_coin_gain_pop(amount: int) -> void:
	if coin_gain_label != null and is_instance_valid(coin_gain_label):
		coin_gain_label.queue_free()

	coin_gain_label = Label.new()
	coin_gain_label.text = "+%d" % amount
	coin_gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_gain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_gain_label.add_theme_font_size_override("font_size", 19)
	coin_gain_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.58, 1.0))
	coin_gain_label.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.018, 0.012, 0.72), Color(0.95, 0.75, 0.34, 0.66), 1, 3))
	add_child(coin_gain_label)
	_set_control_rect(coin_gain_label, Rect2(Vector2(-134.0, -106.0), Vector2(106.0, 32.0)))
	coin_gain_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	coin_gain_label.offset_left = -134.0
	coin_gain_label.offset_top = -176.0
	coin_gain_label.offset_right = -28.0
	coin_gain_label.offset_bottom = -144.0
	coin_gain_label.scale = Vector2.ONE * 0.88
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(coin_gain_label, "scale", Vector2.ONE * 1.18, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin_gain_label, "offset_top", -192.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin_gain_label, "offset_bottom", -160.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_gain_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_queue_free_instance_id.bind(coin_gain_label.get_instance_id()))


func _queue_free_instance_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id)
	if node is Node:
		node.queue_free()


func _hide_instance_id(instance_id: int) -> void:
	var control := instance_from_id(instance_id)
	if control is CanvasItem:
		control.hide()


func _style_hint_label(label: Label, center_text: bool) -> void:
	label.remove_theme_stylebox_override("normal")
	label.add_theme_font_size_override("font_size", 28 if center_text else 22)
	label.add_theme_color_override("font_color", Color(0.90, 0.96, 0.95, 0.94))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _is_demo_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path.begins_with("res://demo/")


func _on_inventory_changed(items: Dictionary) -> void:
	_update_inventory_text(items)
	_update_shop()


func _on_first_item_obtained(_item_name: String) -> void:
	if GameState.has_shown_inventory_tutorial:
		return

	GameState.has_shown_inventory_tutorial = true
	show_toast(_t("INVENTORY_FIRST_HINT"), 3.2)


func _format_action_text(text: String) -> String:
	var input_settings: Node = get_node_or_null("/root/InputSettings")
	if input_settings == null:
		return text
	return String(input_settings.call("format_action_text", text))


func _t(key: String) -> String:
	var override := _demo_text_override(key)
	if override != "":
		return override
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", key))
	return key


func _demo_text_override(key: String) -> String:
	var localization: Node = _get_localization()
	var is_en := localization != null and String(localization.get("current_locale")) == "en"
	var exhibition_labels := {
		"CURRENCY_AMOUNT": ["寶特瓶：%d", "Bottles: %d"],
		"TOAST_COIN": ["回收寶特瓶 +%d", "Recycled bottle +%d"],
		"INVENTORY_FIRST_HINT": ["按 {inventory} 可以查看背包與回收資源。", "Press {inventory} to check your bag and recycled resources."],
		"DIALOGUE_NEXT_HINT": ["Enter 或 {interact}：繼續 / Esc：離開", "Enter or {interact}: Continue / Esc: Leave"],
		"DIALOGUE_SHOP_HINT": ["Enter 或 {interact}：查看補給 / Esc：離開", "Enter or {interact}: Browse supplies / Esc: Leave"],
		"SHOP_TITLE": ["%s 的回收補給站", "%s's Recycling Supply"],
		"SHOP_INVENTORY_HINT": ["用回收寶特瓶交換補給。", "Trade recycled bottles for supplies."],
		"SHOP_OWNED": ["已取得", "Owned"],
		"SHOP_LIMIT": ["已達上限", "Limit reached"],
		"SHOP_ITEM_LINE": ["%s\n需要 %d 個寶特瓶 %s\n%s", "%s\nCosts %d bottles %s\n%s"],
		"SHOP_HINT": ["方向鍵選擇 / Enter 或 {interact}：購買 / {inventory} 或 Esc：關閉", "Arrow keys: Select / Enter or {interact}: Buy / {inventory} or Esc: Close"],
		"SHOP_ALREADY_HAVE": ["已經擁有：%s", "Already owned: %s"],
		"SHOP_POTION_LIMIT": ["回復藥水已達上限。", "Potion limit reached."],
		"SHOP_NOT_ENOUGH_MONEY": ["寶特瓶不足。", "Not enough bottles."],
		"SHOP_GOT_ITEM": ["取得：%s", "Got: %s"],
		"ITEM_HEALTH_POTION": ["回復藥水", "Recovery Potion"],
		"ITEM_HEALTH_POTION_DESC": ["補回一次生命。", "Restores one health."],
		"ITEM_ROUGH_CHARM": ["粗糙護符", "Rough Charm"],
		"ITEM_ROUGH_CHARM_DESC": ["由回收零件拼成的小護符。", "A small charm made from reused parts."],
		"ITEM_OLD_MAP": ["破舊地圖", "Old Map"],
		"ITEM_OLD_MAP_DESC": ["標記附近通道。", "Marks nearby paths."],
		"ITEM_TRAVELER_NOTE": ["旅行筆記", "Traveler Note"],
		"ITEM_TRAVELER_NOTE_DESC": ["記錄海溝中的觀察。", "Notes from the trench."],
	}
	if exhibition_labels.has(key):
		var exhibition_pair: Array = exhibition_labels[key]
		return String(exhibition_pair[1] if is_en else exhibition_pair[0])
	var clean_labels := {
		"CURRENCY_AMOUNT": ["金錢：%d", "Coins: %d"],
		"INV_TAB_BAG": ["背包", "Bag"],
		"INV_TAB_SKILLS": ["技能", "Skills"],
		"INV_TAB_MAP": ["地圖", "Map"],
		"INV_CAT_ALL": ["全部", "All"],
		"INV_CAT_CONSUMABLE": ["消耗品", "Consumables"],
		"INV_CAT_MATERIAL": ["素材", "Materials"],
		"INV_CAT_SKILL": ["技能", "Skills"],
		"INV_CAT_IMPORTANT": ["重要", "Important"],
		"INV_EQUIPPED_SKILLS": ["裝備中的技能", "Equipped Skills"],
		"INV_SKILL_SLOT": ["技能格 %d", "Skill Slot %d"],
		"INV_SKILL_SLOT_EMPTY": ["技能格 %d\n未裝備", "Skill Slot %d\nEmpty"],
		"INV_SKILL_SLOT_EQUIPPED": ["技能格 %d\n%s", "Skill Slot %d\n%s"],
		"INV_HINT": ["Tab：換頁 / 方向鍵：選擇 / Enter：裝備 / {inventory} 或 Esc：關閉", "Tab: Page / Arrow keys: Select / Enter: Equip / {inventory} or Esc: Close"],
		"INV_SELECT_ITEM": ["選擇一個項目", "Select an item"],
		"INV_DEFAULT_DESC": ["背包物品與技能都會在這裡整理。", "Bag items and skills are managed here."],
		"INV_SKILL_TREE": ["潮汐模組", "Tide Modules"],
		"INV_SKILL_TREE_DESC": ["每組兩個模組會產生共鳴。能量蓄滿後，長按 {far_attack} 釋放組合技。", "Each pair resonates as a set. When charged, hold {far_attack} to release its combo skill."],
		"INV_SKILL_WATER_DASH": ["水中衝刺", "Underwater Dash"],
		"INV_SKILL_WATER_DASH_DESC": ["按 {dash} 可朝目前方向快速衝刺，適合穿越危險區域。", "Press {dash} to dash quickly underwater toward the held direction."],
		"INV_SKILL_WALL_BURST": ["牆面爆發", "Wall Burst"],
		"INV_SKILL_WALL_BURST_DESC": ["貼牆時按跳躍鍵 {jump} 可以借力彈開。", "Press {jump} to burst away while touching a wall."],
		"INV_SKILL_WATER_SHOT": ["水槍", "Water Shot"],
		"INV_SKILL_WATER_SHOT_DESC": ["按 {far_attack} 發射直線水彈，適合在安全距離打斷或補刀敵人。使用後需等待 3 秒冷卻。", "Press {far_attack} to fire a straight water shot. It is useful for safe ranged hits and has a 3-second cooldown."],
		"INV_SKILL_QUICK_MAP": ["快速地圖", "Quick Map"],
		"INV_SKILL_QUICK_MAP_DESC": ["按 {map} 可切換小地圖與完整地圖，地圖開啟時仍會更新玩家位置。", "Press {map} to switch between mini map and full map."],
		"MAP_TITLE": ["區域地圖", "Area Map"],
		"MAP_HINT": ["{map} / Esc：關閉", "{map} / Esc: Close"],
		"MAP_EMPTY": ["這個場景還沒有地圖標記。", "This scene has no map markers yet."],
	}
	if clean_labels.has(key):
		var clean_pair: Array = clean_labels[key]
		return String(clean_pair[1] if is_en else clean_pair[0])
	var labels := {
		"CURRENCY_AMOUNT": ["金錢：%d", "Coins: %d"],
		"INV_TAB_BAG": ["背包", "Bag"],
		"INV_TAB_SKILLS": ["技能", "Skills"],
		"INV_TAB_MAP": ["地圖", "Map"],
		"INV_CAT_ALL": ["全部", "All"],
		"INV_CAT_CONSUMABLE": ["消耗品", "Consumables"],
		"INV_CAT_MATERIAL": ["材料", "Materials"],
		"INV_CAT_SKILL": ["技能", "Skills"],
		"INV_CAT_IMPORTANT": ["重要", "Important"],
		"INV_EQUIPPED_SKILLS": ["裝備技能", "Equipped Skills"],
		"INV_SKILL_SLOT": ["技能 %d", "Skill %d"],
		"INV_SKILL_SLOT_EMPTY": ["技能 %d\n未裝備", "Skill %d\nEmpty"],
		"INV_SKILL_SLOT_EQUIPPED": ["技能 %d\n%s", "Skill %d\n%s"],
		"INV_HINT": ["Tab：切換頁面 / 方向鍵：選擇 / Enter 或 E：裝備 / I 或 Esc：關閉", "Tab: Switch page / Arrow keys: Select / Enter or E: Equip / I or Esc: Close"],
		"INV_SELECT_ITEM": ["選擇一個項目", "Select an item"],
		"INV_DEFAULT_DESC": ["背包物品與技能都會在這裡整理。", "Bag items and skills are managed here."],
		"INV_SKILL_TREE": ["技能欄", "Skill Loadout"],
		"INV_SKILL_WATER_DASH": ["水中衝刺", "Underwater Dash"],
		"INV_SKILL_WATER_DASH_DESC": ["在水中朝指定方向快速衝刺。", "Dash quickly underwater toward the held direction."],
		"INV_SKILL_WALL_BURST": ["牆面爆發", "Wall Burst"],
		"INV_SKILL_WALL_BURST_DESC": ["貼牆時向外爆發移動。", "Burst away while touching a wall."],
		"INV_SKILL_WATER_SHOT": ["水彈", "Water Shot"],
		"INV_SKILL_WATER_SHOT_DESC": ["發射遠距離水彈。", "Fire a ranged water shot."],
		"INV_SKILL_QUICK_MAP": ["快速地圖", "Quick Map"],
		"INV_SKILL_QUICK_MAP_DESC": ["切換小地圖與完整地圖。", "Switch between mini map and full map."],
		"MAP_TITLE": ["區域地圖", "Area Map"],
		"MAP_HINT": ["M / Esc：關閉", "M / Esc: Close"],
		"MAP_EMPTY": ["這個場景還沒有地圖標記。", "This scene has no map markers yet."],
	}
	if not labels.has(key):
		return ""
	var pair: Array = labels[key]
	return String(pair[1] if is_en else pair[0])


func _tr_raw(text: String) -> String:
	var localization: Node = _get_localization()
	if localization != null and localization.has_method("translate_raw"):
		return String(localization.call("translate_raw", text))
	return text


func _get_localization() -> Node:
	return get_node_or_null("/root/Localization")


func _apply_demo_ui_fonts() -> void:
	var body_font := load(DEMO_UI_FONT_PATH)
	if body_font is Font:
		for child in get_children():
			if child is Control:
				_apply_font_to_control_tree(child, body_font)


func _apply_font_to_control_tree(control: Control, font: Font) -> void:
	control.add_theme_font_override("font", font)
	for child in control.get_children():
		if child is Control:
			_apply_font_to_control_tree(child, font)


func _refresh_localized_texts() -> void:
	if inventory_title_label != null:
		inventory_title_label.text = _t(selected_inventory_tab_key)
	map_title_label.text = _t("MAP_TITLE")
	map_hint_label.text = _format_action_text(_t("MAP_HINT"))
	_on_currency_changed(GameState.currency)
	if dialogue_panel.visible:
		if active_npc != null:
			dialogue_name_label.text = _tr_raw(active_npc.display_name)
		_show_dialogue_line()
	if inventory_panel.visible:
		_update_inventory_text(GameState.inventory)
	if shop_panel.visible:
		_update_shop()
	if map_panel.visible:
		_rebuild_map()


func _on_controls_changed() -> void:
	_refresh_localized_texts()
	if prompt_label.visible:
		prompt_label.text = _format_action_text(_tr_raw(current_prompt_text))
	if toast_label.visible:
		toast_label.text = _format_action_text(_tr_raw(current_toast_text))


func _on_map_room_changed(_scene_path: String, _room_id: String) -> void:
	if map_panel.visible:
		_rebuild_map()


func _build_inventory_window() -> void:
	for child in inventory_panel.get_children():
		child.queue_free()

	inventory_tab_buttons.clear()
	inventory_category_buttons.clear()
	equipped_skill_slots.clear()

	_center_control(inventory_panel, Vector2(1540.0, 820.0))
	inventory_panel.add_theme_stylebox_override("panel", DEMO_MENU_UI_ART.inventory_panel_style())

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 34.0
	root.offset_top = 24.0
	root.offset_right = -34.0
	root.offset_bottom = -24.0
	root.add_theme_constant_override("separation", 18)
	inventory_panel.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 46)
	header.add_theme_constant_override("separation", 0)
	root.add_child(header)

	inventory_title_label = Label.new()
	inventory_title_label.text = _t("INV_TAB_BAG")
	inventory_title_label.custom_minimum_size = Vector2.ZERO
	inventory_title_label.visible = false
	inventory_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_title_label.add_theme_font_size_override("font_size", 30)
	inventory_title_label.add_theme_color_override("font_color", Color(0.9, 0.96, 0.96, 0.96))
	header.add_child(inventory_title_label)

	var tabs := HBoxContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 18)
	header.add_child(tabs)
	for tab_key in INVENTORY_TAB_KEYS:
		var tab_button := _make_tab_button(_t(tab_key))
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.set_meta("locale_key", tab_key)
		tab_button.pressed.connect(_select_inventory_tab.bind(tab_key))
		tabs.add_child(tab_button)
		inventory_tab_buttons.append(tab_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 28)
	root.add_child(body)

	inventory_profile_label = Label.new()

	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(680, 0)
	center.add_theme_constant_override("separation", 12)
	body.add_child(center)

	inventory_category_row = HBoxContainer.new()
	inventory_category_row.custom_minimum_size = Vector2(0, 38)
	inventory_category_row.add_theme_constant_override("separation", 8)
	center.add_child(inventory_category_row)
	for category_key in INVENTORY_CATEGORY_KEYS:
		var category_button := _make_tab_button(_t(category_key))
		category_button.set_meta("locale_key", category_key)
		category_button.pressed.connect(_select_inventory_category.bind(category_key))
		inventory_category_row.add_child(category_button)
		inventory_category_buttons.append(category_button)

	inventory_equipped_title_label = Label.new()
	inventory_equipped_title_label.text = _t("INV_EQUIPPED_SKILLS")
	inventory_equipped_title_label.custom_minimum_size = Vector2(0, 38)
	inventory_equipped_title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	inventory_equipped_title_label.add_theme_font_size_override("font_size", 22)
	inventory_equipped_title_label.add_theme_color_override("font_color", Color(0.9, 0.96, 0.96, 0.92))
	center.add_child(inventory_equipped_title_label)

	inventory_equipped_grid = HBoxContainer.new()
	inventory_equipped_grid.add_theme_constant_override("separation", 12)
	center.add_child(inventory_equipped_grid)
	for i in range(EQUIPPED_SKILL_SLOT_COUNT):
		if i == 2:
			var divider := ColorRect.new()
			divider.custom_minimum_size = Vector2(2, 76)
			divider.color = Color(0.72, 0.86, 0.9, 0.5)
			inventory_equipped_grid.add_child(divider)
		var slot_size := Vector2(142, 74)
		var slot := _make_slot_button(_t("INV_SKILL_SLOT") % (i + 1), slot_size)
		slot.pressed.connect(_equip_selected_skill_to_slot.bind(i))
		inventory_equipped_grid.add_child(slot)
		equipped_skill_slots.append(slot)

	inventory_skill_separator = ColorRect.new()
	inventory_skill_separator.custom_minimum_size = Vector2(0, 1)
	inventory_skill_separator.color = Color(0.55, 0.68, 0.72, 0.45)
	center.add_child(inventory_skill_separator)

	inventory_grid_scroll = ScrollContainer.new()
	inventory_grid_scroll.custom_minimum_size = Vector2(608, 0)
	inventory_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_grid_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	inventory_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(inventory_grid_scroll)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 3
	inventory_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_grid.add_theme_constant_override("h_separation", 14)
	inventory_grid.add_theme_constant_override("v_separation", 14)
	inventory_grid_scroll.add_child(inventory_grid)

	var detail_panel := VBoxContainer.new()
	detail_panel.custom_minimum_size = Vector2(390, 0)
	detail_panel.add_theme_constant_override("separation", 14)
	body.add_child(detail_panel)

	inventory_detail_icon = TextureRect.new()
	inventory_detail_icon.custom_minimum_size = Vector2(210, 190)
	inventory_detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inventory_detail_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	inventory_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_panel.add_child(inventory_detail_icon)

	inventory_currency_label = Label.new()
	inventory_currency_label.add_theme_font_size_override("font_size", 17)
	inventory_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_panel.add_child(inventory_currency_label)

	inventory_detail_title = Label.new()
	inventory_detail_title.add_theme_font_size_override("font_size", 24)
	inventory_detail_title.add_theme_color_override("font_color", Color(0.92, 0.98, 0.98, 0.95))
	detail_panel.add_child(inventory_detail_title)

	inventory_detail_type = Label.new()
	inventory_detail_type.add_theme_font_size_override("font_size", 15)
	inventory_detail_type.add_theme_color_override("font_color", Color(0.68, 0.82, 0.84, 0.82))
	detail_panel.add_child(inventory_detail_type)

	inventory_skill_meta_label = Label.new()
	inventory_skill_meta_label.add_theme_font_size_override("font_size", 16)
	inventory_skill_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_skill_meta_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.78, 0.9))
	detail_panel.add_child(inventory_skill_meta_label)

	inventory_detail_description = Label.new()
	inventory_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_detail_description.add_theme_font_size_override("font_size", 17)
	inventory_detail_description.clip_text = true
	inventory_detail_description.custom_minimum_size = Vector2(0, 220)
	inventory_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(inventory_detail_description)

	inventory_profile_panel = VBoxContainer.new()
	inventory_profile_panel.custom_minimum_size = Vector2(260, 0)
	inventory_profile_panel.add_theme_constant_override("separation", 10)
	body.add_child(inventory_profile_panel)

	inventory_profile_title_label = Label.new()
	inventory_profile_title_label.text = "角色資料"
	inventory_profile_title_label.add_theme_font_size_override("font_size", 20)
	inventory_profile_title_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 0.96))
	inventory_profile_panel.add_child(inventory_profile_title_label)

	inventory_profile_label.add_theme_font_size_override("font_size", 16)
	inventory_profile_label.add_theme_color_override("font_color", Color(0.78, 0.76, 0.66, 0.92))
	inventory_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_profile_panel.add_child(inventory_profile_label)

	inventory_hint_label = Label.new()
	inventory_hint_label.text = _format_action_text(_t("INV_HINT"))
	inventory_hint_label.add_theme_font_size_override("font_size", 14)
	inventory_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	inventory_hint_label.custom_minimum_size = Vector2(0, 48)
	inventory_hint_label.add_theme_color_override("font_color", Color(0.74, 0.86, 0.86, 0.78))
	detail_panel.add_child(inventory_hint_label)


func _reset_equipped_skills() -> void:
	equipped_skills.clear()
	for i in range(EQUIPPED_SKILL_SLOT_COUNT):
		equipped_skills.append(_skill_for_saved_slot(i))


func _skill_for_saved_slot(index: int) -> Dictionary:
	var saved_id := String(GameState.equipped_skill_ids[index]) if index < GameState.equipped_skill_ids.size() else ""
	var saved_icon := String(GameState.equipped_skill_icons[index]) if index < GameState.equipped_skill_icons.size() else ""
	for skill in SKILL_LIBRARY:
		if saved_id != "" and String(skill.get("id", "")) == saved_id:
			return skill.duplicate(true)
		if saved_icon != "" and String(skill.get("texture", "")) == saved_icon:
			return skill.duplicate(true)
	if index == 0:
		for skill in SKILL_LIBRARY:
			if String(skill.get("id", "")) == "water_shot":
				return skill.duplicate(true)
	return {}


func _select_inventory_tab(tab_key: String) -> void:
	selected_inventory_tab_key = tab_key
	selected_inventory_category_focus_index = -1
	if tab_key != "INV_TAB_SKILLS":
		selected_equip_slot_index = -1
	if tab_key == "INV_TAB_MAP":
		close_all_windows()
		_show_full_map()
		return
	_update_inventory_text(GameState.inventory)


func _select_inventory_category(category_key: String) -> void:
	selected_inventory_category_key = category_key
	_update_inventory_text(GameState.inventory)


func _update_inventory_text(items: Dictionary) -> void:
	if inventory_grid == null:
		return

	_refresh_inventory_header()
	_refresh_inventory_buttons()
	_refresh_equipped_skill_slots()
	_rebuild_inventory_grid(items)


func _refresh_inventory_header() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var hp_text := "?"
	var max_hp_text := "?"
	if player != null:
		hp_text = "%s" % player.current_health
		max_hp_text = "%s" % player.max_health

	var is_skill_tab := selected_inventory_tab_key == "INV_TAB_SKILLS"
	var is_bag_tab := selected_inventory_tab_key == "INV_TAB_BAG"
	inventory_title_label.text = ""
	if inventory_profile_panel != null:
		inventory_profile_panel.visible = is_bag_tab
	if inventory_category_row != null:
		inventory_category_row.visible = is_bag_tab
	if inventory_currency_label != null:
		inventory_currency_label.visible = is_bag_tab
	if inventory_grid_scroll != null:
		inventory_grid_scroll.custom_minimum_size = Vector2(660, 0) if is_skill_tab else Vector2(608, 0)
	if inventory_equipped_title_label != null:
		inventory_equipped_title_label.text = _t("INV_EQUIPPED_SKILLS")
		inventory_equipped_title_label.visible = is_skill_tab
	if inventory_equipped_grid != null:
		inventory_equipped_grid.visible = is_skill_tab
	if inventory_skill_separator != null:
		inventory_skill_separator.visible = is_skill_tab
	if inventory_hint_label != null:
		inventory_hint_label.text = _format_action_text(_t("INV_HINT")) if is_skill_tab else ""
	if inventory_skill_meta_label != null:
		inventory_skill_meta_label.visible = is_skill_tab
		inventory_skill_meta_label.text = ""
	if inventory_profile_title_label != null:
		inventory_profile_title_label.text = "角色資料"
	inventory_profile_label.text = "生命值：%s / %s\n回收寶特瓶：%d\n回復藥水：%d\n裝備技能格：%d" % [hp_text, max_hp_text, GameState.currency, GameState.get_health_potion_count(), EQUIPPED_SKILL_SLOT_COUNT]
	inventory_currency_label.text = _t("CURRENCY_AMOUNT") % GameState.currency
	inventory_detail_title.text = "選取中的技能介紹" if is_skill_tab else _t("INV_TAB_BAG")
	inventory_detail_type.text = ""
	inventory_detail_description.text = _t("INV_DEFAULT_DESC") if is_bag_tab else _format_action_text("四個技能格分成兩組。遊戲中按 {skill_group_switch} 可切換左下角顯示的兩個技能。")
	if inventory_detail_icon != null:
		inventory_detail_icon.texture = null


func _refresh_inventory_buttons() -> void:
	for button in inventory_tab_buttons:
		var tab_key := String(button.get_meta("locale_key", ""))
		button.text = _t(tab_key)
		button.button_pressed = tab_key == selected_inventory_tab_key
	for button in inventory_category_buttons:
		var category_key := String(button.get_meta("locale_key", ""))
		button.text = _t(category_key)
		button.button_pressed = category_key == selected_inventory_category_key
		button.visible = selected_inventory_tab_key == "INV_TAB_BAG"


func _refresh_equipped_skill_slots() -> void:
	var equipped_icon_paths: Array[String] = []
	var equipped_ids: Array[String] = []
	for i in range(equipped_skill_slots.size()):
		var slot := equipped_skill_slots[i]
		slot.visible = selected_inventory_tab_key == "INV_TAB_SKILLS"
		slot.toggle_mode = true
		slot.button_pressed = i == selected_equip_slot_index
		var skill: Dictionary = equipped_skills[i]
		var slot_name := "技能組 %d - 格 %d" % [floori(float(i) / 2.0) + 1, (i % 2) + 1]
		if skill.is_empty():
			slot.text = "%s\n未裝備" % slot_name
			slot.icon = null
			equipped_icon_paths.append("")
			equipped_ids.append("")
		else:
			slot.text = "%s\n%s" % [slot_name, _entry_name(skill)]
			slot.icon = _load_texture(String(skill.get("texture", "")), SKILL_TEXTURE)
			equipped_icon_paths.append(String(skill.get("texture", "")))
			equipped_ids.append(String(skill.get("id", "")))
		if i == selected_equip_slot_index:
			slot.text = "選取中\n" + slot.text
	GameState.set_equipped_skills(equipped_ids, equipped_icon_paths)


func _rebuild_inventory_grid(items: Dictionary) -> void:
	for child in inventory_grid.get_children():
		child.queue_free()
	inventory_entry_buttons.clear()
	inventory_current_entries.clear()

	if selected_inventory_tab_key == "INV_TAB_SKILLS":
		inventory_grid.columns = 1
		inventory_grid.add_child(_make_skill_tree_panel())
		_select_first_inventory_entry()
		return

	inventory_grid.columns = 3
	var entries := _get_inventory_entries(items)
	inventory_current_entries = entries
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = _t("INVENTORY_EMPTY")
		empty_label.custom_minimum_size = Vector2(640, 86)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.88, 0.72))
		inventory_grid.add_child(empty_label)
		return
	for entry_index in range(entries.size()):
		var entry := entries[entry_index]
		var button := _make_inventory_cell(entry)
		button.pressed.connect(_select_inventory_entry_at.bind(entry_index))
		inventory_grid.add_child(button)
		inventory_entry_buttons.append(button)
	for _i in range(maxi(0, GRID_SLOT_COUNT - entries.size())):
		inventory_grid.add_child(_make_empty_cell())
	_select_first_inventory_entry()


func _get_inventory_entries(items: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if selected_inventory_tab_key == "INV_TAB_SKILLS":
		for skill in SKILL_LIBRARY:
			entries.append(skill.duplicate(true).merged({"kind": "skill"}))
	elif selected_inventory_tab_key == "INV_TAB_BAG":
		for item_name in items.keys():
			var raw_name := String(item_name)
			var item_type_key := _get_item_type_key(raw_name)
			if selected_inventory_category_key != "INV_CAT_ALL" and selected_inventory_category_key != item_type_key:
				continue
			entries.append({
				"name": GameState.get_item_display_name(raw_name),
				"raw_name": raw_name,
				"amount": int(items[item_name]),
				"type_key": item_type_key,
				"description": GameState.get_item_description(raw_name),
				"kind": "item",
				"texture": _inventory_texture_for_item(raw_name),
			})

	return entries


func _inventory_texture_for_item(item_name: String) -> String:
	if GameState.is_health_potion_item(item_name):
		return "res://demo/assets/art/legacy/some/Health_Potion.png"
	if item_name == GameState.STARTER_ITEM:
		return "res://demo/assets/art/legacy/useicon_white.png"
	return "res://demo/assets/hollow_import/effects/glow_bug_01.png"


func _make_skill_tree_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(690, 460)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = _format_action_text(_t("INV_SKILL_TREE"))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.96, 0.96, 0.92))
	panel.add_child(title)

	var description := Label.new()
	description.text = _format_action_text(_t("INV_SKILL_TREE_DESC"))
	description.add_theme_font_size_override("font_size", 15)
	description.add_theme_color_override("font_color", Color(0.72, 0.88, 0.9, 0.82))
	panel.add_child(description)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	panel.add_child(grid)

	for i in range(SKILL_LIBRARY.size()):
		var skill: Dictionary = SKILL_LIBRARY[i]
		var entry := skill.duplicate(true).merged({"kind": "skill"})
		var entry_index := inventory_current_entries.size()
		var skill_button := _make_skill_node_button(skill)
		skill_button.pressed.connect(_select_inventory_entry_at.bind(entry_index))
		grid.add_child(skill_button)
		inventory_entry_buttons.append(skill_button)
		inventory_current_entries.append(entry)
	for _i in range(20):
		grid.add_child(_make_empty_cell())

	return panel


func _make_skill_node_button(skill: Dictionary) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = _entry_name(skill)
	button.icon = _load_texture(String(skill.get("texture", "")), SKILL_TEXTURE)
	button.custom_minimum_size = Vector2(150, 116)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 0.96))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.035, 0.044, 0.84), Color(0.44, 0.68, 0.74, 0.5), 1, 5))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.05, 0.09, 0.105, 0.92), Color(0.68, 0.9, 0.95, 0.72), 1, 5))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.13, 0.11, 0.05, 0.94), Color(1.0, 0.76, 0.28, 0.8), 1, 5))
	button.add_theme_stylebox_override("focus", _make_style(Color(0.05, 0.09, 0.105, 0.92), Color(1.0, 0.8, 0.35, 0.88), 1, 5))
	return button


func _get_item_type_key(item_name: String) -> String:
	if GameState.is_health_potion_item(item_name):
		return "INV_CAT_CONSUMABLE"
	if GameState.is_rough_charm_item(item_name):
		return "INV_CAT_IMPORTANT"
	if item_name.to_lower().contains("skill"):
		return "INV_CAT_SKILL"
	return "INV_CAT_MATERIAL"


func _make_inventory_cell(entry: Dictionary) -> Button:
	var button := _make_slot_button("", Vector2(184, 88))
	button.toggle_mode = true
	button.text = "%s\nx%d" % [_entry_name(entry), int(entry.get("amount", 1))] if entry.get("kind", "item") == "item" else _entry_name(entry)
	button.icon = _load_texture(String(entry.get("texture", "")), SKILL_TEXTURE if entry.get("kind") == "skill" else ITEM_TEXTURE)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 14)
	return button


func _select_first_inventory_entry(activate := true) -> void:
	if inventory_current_entries.is_empty():
		selected_inventory_grid_index = -1
		return
	_select_inventory_entry_at(0, activate)


func _select_inventory_entry_at(index: int, activate := true) -> void:
	if index < 0 or index >= inventory_current_entries.size():
		return
	selected_inventory_category_focus_index = -1
	selected_inventory_grid_index = index
	for i in range(inventory_entry_buttons.size()):
		inventory_entry_buttons[i].set_pressed_no_signal(i == selected_inventory_grid_index)
	_on_inventory_entry_pressed(inventory_current_entries[index], activate)
	if index < inventory_entry_buttons.size():
		inventory_entry_buttons[index].grab_focus()


func _handle_inventory_navigation(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false

	if event.is_action_pressed("ui_focus_next"):
		_cycle_inventory_tab(1)
		return true
	if event.is_action_pressed("ui_focus_prev"):
		_cycle_inventory_tab(-1)
		return true

	if selected_inventory_tab_key == "INV_TAB_BAG" and selected_inventory_category_focus_index >= 0:
		if event.is_action_pressed("ui_left"):
			_focus_inventory_category(selected_inventory_category_focus_index - 1)
			return true
		if event.is_action_pressed("ui_right"):
			_focus_inventory_category(selected_inventory_category_focus_index + 1)
			return true
		if event.is_action_pressed("ui_down"):
			_select_first_inventory_entry(false)
			return true

	if selected_inventory_tab_key == "INV_TAB_SKILLS" and selected_equip_slot_index >= 0 and _is_equipped_skill_slot_focused():
		if event.is_action_pressed("ui_left"):
			_focus_equipped_skill_slot(selected_equip_slot_index - 1)
			return true
		if event.is_action_pressed("ui_right"):
			_focus_equipped_skill_slot(selected_equip_slot_index + 1)
			return true
		if event.is_action_pressed("ui_down"):
			_select_first_inventory_entry(false)
			return true

	var columns := 4 if selected_inventory_tab_key == "INV_TAB_SKILLS" else 3
	var delta := 0
	if event.is_action_pressed("ui_left"):
		delta = -1
	elif event.is_action_pressed("ui_right"):
		delta = 1
	elif event.is_action_pressed("ui_up"):
		if selected_inventory_grid_index < columns:
			if selected_inventory_tab_key == "INV_TAB_SKILLS":
				_focus_equipped_skill_slot(0)
			elif selected_inventory_tab_key == "INV_TAB_BAG":
				_focus_inventory_category(0)
			return true
		delta = -columns
	elif event.is_action_pressed("ui_down"):
		delta = columns
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if selected_inventory_grid_index >= 0 and selected_inventory_grid_index < inventory_current_entries.size():
			_on_inventory_entry_pressed(inventory_current_entries[selected_inventory_grid_index], true)
		return true
	else:
		return false

	if inventory_current_entries.is_empty():
		return true
	var next_index := clampi(maxi(selected_inventory_grid_index, 0) + delta, 0, inventory_current_entries.size() - 1)
	_select_inventory_entry_at(next_index, false)
	return true


func _is_equipped_skill_slot_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner != null and equipped_skill_slots.has(focus_owner)


func _cycle_inventory_tab(direction: int) -> void:
	var tab_index := INVENTORY_TAB_KEYS.find(selected_inventory_tab_key)
	_select_inventory_tab(INVENTORY_TAB_KEYS[wrapi(tab_index + direction, 0, INVENTORY_TAB_KEYS.size())])


func _focus_inventory_category(index: int) -> void:
	if inventory_category_buttons.is_empty():
		return
	selected_inventory_category_focus_index = wrapi(index, 0, inventory_category_buttons.size())
	_select_inventory_category(INVENTORY_CATEGORY_KEYS[selected_inventory_category_focus_index])
	selected_inventory_category_focus_index = wrapi(index, 0, inventory_category_buttons.size())
	inventory_category_buttons[selected_inventory_category_focus_index].grab_focus()


func _focus_equipped_skill_slot(index: int) -> void:
	if equipped_skill_slots.is_empty():
		return
	_equip_selected_skill_to_slot(clampi(index, 0, equipped_skill_slots.size() - 1))
	equipped_skill_slots[selected_equip_slot_index].grab_focus()


func _make_empty_cell() -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(150, 86) if selected_inventory_tab_key == "INV_TAB_SKILLS" else Vector2(184, 88)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.01, 0.012, 0.016, 0.55), Color(0.28, 0.34, 0.38, 0.55), 1, 2))
	return panel


func _on_inventory_entry_pressed(entry: Dictionary, activate := true) -> void:
	var is_skill: bool = entry.get("kind") == "skill"
	inventory_detail_title.text = _entry_name(entry)
	inventory_detail_type.text = "" if is_skill else _entry_type(entry)
	if inventory_skill_meta_label != null:
		inventory_skill_meta_label.visible = is_skill
		inventory_skill_meta_label.text = "分類：%s\n冷卻時間：%s" % [_entry_type(entry), String(entry.get("cooldown", "無"))] if is_skill else ""
	inventory_detail_description.text = _entry_description(entry)
	if inventory_detail_icon != null:
		inventory_detail_icon.texture = _load_texture(String(entry.get("texture", "")), SKILL_TEXTURE if is_skill else ITEM_TEXTURE)
	if is_skill:
		selected_skill_for_equip = entry.duplicate(true)
		if activate and selected_equip_slot_index >= 0 and selected_equip_slot_index < equipped_skills.size():
			var equipped_slot_index := selected_equip_slot_index
			equipped_skills[equipped_slot_index] = selected_skill_for_equip.duplicate(true)
			selected_equip_slot_index = -1
			_refresh_equipped_skill_slots()
			GameState.set_active_skill_group(floori(float(equipped_slot_index) / 2.0))
			GameState.save_game()
			inventory_detail_type.text = "已裝備"


func _equip_selected_skill_to_slot(index: int) -> void:
	if index < 0 or index >= equipped_skills.size():
		return
	selected_equip_slot_index = index
	inventory_detail_title.text = "技能組 %d - 格 %d" % [floori(float(index) / 2.0) + 1, (index % 2) + 1]
	inventory_detail_type.text = "已安裝"
	if inventory_skill_meta_label != null:
		inventory_skill_meta_label.visible = true
		inventory_skill_meta_label.text = "分類：技能\n冷卻時間：3 秒"
	inventory_detail_description.text = _format_action_text("選擇下方技能後會安裝到這一格。遊戲中按 {skill_group_switch} 可切換兩組技能。")
	if inventory_detail_icon != null:
		inventory_detail_icon.texture = null
	_refresh_equipped_skill_slots()


func _clear_equipped_skill(index: int) -> void:
	if index < 0 or index >= equipped_skills.size():
		return
	equipped_skills[index] = {}
	selected_equip_slot_index = -1
	_refresh_equipped_skill_slots()
	GameState.save_game()


func _make_tab_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 0.96))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _make_style(Color(0.01, 0.018, 0.024, 0.72), Color(0.5, 0.78, 0.84, 0.42), 1, 3))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.04, 0.075, 0.09, 0.86), Color(0.7, 0.95, 1.0, 0.66), 1, 3))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.1, 0.04, 0.9), Color(1.0, 0.76, 0.28, 0.8), 1, 3))
	button.add_theme_stylebox_override("focus", _make_style(Color(0.04, 0.075, 0.09, 0.86), Color(1.0, 0.8, 0.35, 0.86), 1, 3))
	return button


func _make_slot_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 0.96))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_stylebox_override("normal", _make_style(Color(0.008, 0.012, 0.018, 0.72), Color(0.34, 0.46, 0.52, 0.56), 1, 2))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.035, 0.058, 0.07, 0.86), Color(0.62, 0.84, 0.9, 0.74), 1, 2))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.11, 0.085, 0.035, 0.9), Color(1.0, 0.74, 0.26, 0.82), 1, 2))
	button.add_theme_stylebox_override("focus", _make_style(Color(0.035, 0.058, 0.07, 0.86), Color(1.0, 0.8, 0.36, 0.88), 1, 2))
	return button


func _entry_name(entry: Dictionary) -> String:
	if entry.has("name_key"):
		return _t(String(entry["name_key"]))
	return _tr_raw(String(entry.get("name", "")))


func _entry_type(entry: Dictionary) -> String:
	if entry.has("type_key"):
		return _t(String(entry["type_key"]))
	return _tr_raw(String(entry.get("type", "Item")))


func _entry_description(entry: Dictionary) -> String:
	if entry.has("description_key"):
		return _format_action_text(_t(String(entry["description_key"])))
	return _format_action_text(_tr_raw(String(entry.get("description", ""))))


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _load_texture(path: String, fallback: Texture2D) -> Texture2D:
	if path == "":
		return fallback
	var texture := load(path)
	return texture if texture is Texture2D else fallback
