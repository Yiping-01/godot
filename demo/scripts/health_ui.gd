extends CanvasLayer

const HUD_EMBLEM_PATH := "res://demo/assets/hud/new_healthbar.png"
const SKILL_FALLBACK_TEXTURE := preload("res://demo/assets/art/legacy/player/attack_far/far_1.png")

const HUD_SCALE := 0.56
const EMBLEM_SIZE := Vector2(234.0, 244.0)
const HEALTH_BAR_POS := Vector2(190.0, 119.0)
const HEALTH_BAR_SIZE := Vector2(686.0, 44.0)
const HEALTH_FILL_POS := Vector2(199.0, 127.0)
const HEALTH_FILL_SIZE := Vector2(668.0, 28.0)
const LAST_HEALTH_SPIKE_START := 38.0
const LAST_HEALTH_SPIKE_PEAK := 58.0
const LAST_HEALTH_SPIKE_END := 82.0
const LAST_HEALTH_SPIKE_INSET := 22.0
const STAMINA_BAR_POS := Vector2(190.0, 165.0)
const STAMINA_BAR_SIZE := Vector2(585.0, 17.0)
const STAMINA_FILL_POS := Vector2(197.0, 169.0)
const STAMINA_FILL_SIZE := Vector2(571.0, 9.0)
const POTION_DIAMOND_HEIGHT_SCALE := 0.58
const POTION_DIAMOND_OUTLINE_RADIUS := 24.0
const POTION_DIAMOND_FILL_RADIUS := 15.0
const POTION_POINTS := [
	Vector2(278.0, 84.0),
	Vector2(388.0, 84.0),
	Vector2(498.0, 84.0),
]
const ACTIVE_SKILL_SLOT_COUNT := 1
const RESERVE_SKILL_SLOT_COUNT := 0

var hud_root: Control
var health_fill: Polygon2D
var stamina_fill: ColorRect
var potion_fills: Array[Polygon2D] = []

var skill_hud: Control
var skill_icons: Array[Sprite2D] = []
var back_skill_icons: Array[Sprite2D] = []
var skill_slot_panels: Array[Panel] = []
var back_skill_slot_panels: Array[Panel] = []
var skill_cooldown_overlays: Array[ColorRect] = []
var skill_cooldown_labels: Array[Label] = []
var ultimate_fill: ColorRect
var ultimate_charge_max := 100.0
var ultimate_charge_current := 0.0
var skill_swap_tween: Tween


func _ready() -> void:
	layer = 40
	_hide_legacy_nodes()
	_build_top_hud()
	_build_skill_hud()
	_connect_game_state()
	call_deferred("_connect_player")
	_on_health_potions_changed(GameState.get_health_potion_count())
	_update_active_skill_icons()
	_on_ultimate_charge_changed(GameState.ultimate_charge, GameState.ultimate_charge_max)


func _hide_legacy_nodes() -> void:
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).hide()


func _build_top_hud() -> void:
	hud_root = Control.new()
	hud_root.name = "DemoTopHud"
	hud_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_root.position = Vector2(18.0, 10.0)
	hud_root.scale = Vector2.ONE * HUD_SCALE
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	_add_health_bar_frame()

	health_fill = Polygon2D.new()
	health_fill.name = "HealthFill"
	health_fill.color = Color(0.96, 0.25, 0.42, 0.98)
	hud_root.add_child(health_fill)

	_add_stamina_bar_frame()

	stamina_fill = ColorRect.new()
	stamina_fill.name = "StaminaFill"
	stamina_fill.position = STAMINA_FILL_POS
	stamina_fill.size = STAMINA_FILL_SIZE
	stamina_fill.color = Color(1.0, 0.82, 0.08, 0.98)
	stamina_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(stamina_fill)

	for center in POTION_POINTS:
		var outline := Line2D.new()
		outline.points = _diamond_points(center, POTION_DIAMOND_OUTLINE_RADIUS)
		outline.closed = true
		outline.default_color = Color(1.0, 0.68, 0.38, 0.96)
		outline.width = 5.0
		hud_root.add_child(outline)

		var fill := Polygon2D.new()
		fill.color = Color(0.95, 0.16, 0.32, 0.95)
		fill.polygon = _diamond_points(center, POTION_DIAMOND_FILL_RADIUS)
		hud_root.add_child(fill)
		potion_fills.append(fill)

	var emblem := TextureRect.new()
	emblem.name = "HealthEmblem"
	emblem.texture = _load_runtime_texture(HUD_EMBLEM_PATH)
	emblem.position = Vector2.ZERO
	emblem.size = EMBLEM_SIZE
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE as TextureRect.ExpandMode
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED as TextureRect.StretchMode
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(emblem)

func _add_health_bar_frame() -> void:
	var frame := Line2D.new()
	frame.name = "HealthBarFrame"
	frame.points = _health_bar_points(HEALTH_FILL_SIZE.x + 12.0, false)
	frame.closed = true
	frame.default_color = Color(1.0, 0.68, 0.40, 0.98)
	frame.width = 5.0
	hud_root.add_child(frame)


func _add_stamina_bar_frame() -> void:
	var frame := Panel.new()
	frame.name = "StaminaBarFrame"
	frame.position = STAMINA_BAR_POS
	frame.size = STAMINA_BAR_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override(
		"panel",
		_flat_style(Color(0.055, 0.045, 0.008, 0.78), Color(1.0, 0.82, 0.08, 0.96), 2)
	)
	hud_root.add_child(frame)


func _build_skill_hud() -> void:
	skill_hud = Control.new()
	skill_hud.name = "DemoSkillHud"
	skill_hud.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	skill_hud.offset_left = 36.0
	skill_hud.offset_top = -174.0
	skill_hud.offset_right = 330.0
	skill_hud.offset_bottom = -58.0
	skill_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skill_hud)

	var ultimate_panel := Panel.new()
	ultimate_panel.name = "UltimateFrame"
	ultimate_panel.position = Vector2(0.0, 10.0)
	ultimate_panel.size = Vector2(28.0, 98.0)
	ultimate_panel.add_theme_stylebox_override("panel", _round_style(Color(0.018, 0.024, 0.03, 0.78), Color(1.0, 0.82, 0.25, 0.9), 2, 8))
	ultimate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_hud.add_child(ultimate_panel)

	ultimate_fill = ColorRect.new()
	ultimate_fill.name = "UltimateFill"
	ultimate_fill.position = Vector2(6.0, 90.0)
	ultimate_fill.size = Vector2(16.0, 0.0)
	ultimate_fill.color = Color(0.9, 0.66, 1.0, 0.9)
	ultimate_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ultimate_panel.add_child(ultimate_fill)

	for i in range(RESERVE_SKILL_SLOT_COUNT):
		var back_panel := Panel.new()
		back_panel.name = "ReserveSkill%d" % (i + 1)
		back_panel.position = _back_skill_position(i)
		back_panel.size = Vector2(58.0, 58.0)
		back_panel.scale = Vector2.ONE * 0.86
		back_panel.modulate = Color(0.62, 0.78, 0.82, 0.45)
		back_panel.add_theme_stylebox_override("panel", _round_style(Color(0.01, 0.018, 0.024, 0.55), Color(0.58, 0.74, 0.78, 0.52), 2, 29))
		back_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_hud.add_child(back_panel)
		back_skill_slot_panels.append(back_panel)

		var back_icon := Sprite2D.new()
		back_icon.texture = SKILL_FALLBACK_TEXTURE
		back_icon.position = Vector2(29.0, 29.0)
		back_icon.z_index = 10
		back_icon.modulate = Color(0.78, 0.92, 0.96, 0.24)
		_fit_skill_sprite(back_icon, 38.0)
		back_panel.add_child(back_icon)
		back_skill_icons.append(back_icon)

	for i in range(ACTIVE_SKILL_SLOT_COUNT):
		var panel := Panel.new()
		panel.name = "ActiveSkill%d" % (i + 1)
		panel.position = _front_skill_position(i)
		panel.size = Vector2(66.0, 66.0)
		panel.clip_contents = true
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		panel.add_theme_stylebox_override("panel", _round_style(Color(0.014, 0.025, 0.032, 0.72), Color(0.75, 0.9, 0.94, 0.74), 2, 33))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		skill_hud.add_child(panel)
		skill_slot_panels.append(panel)

		var icon := Sprite2D.new()
		icon.texture = SKILL_FALLBACK_TEXTURE
		icon.position = Vector2(33.0, 33.0)
		icon.z_index = 10
		icon.modulate = Color(0.78, 0.92, 0.96, 0.2)
		_fit_skill_sprite(icon, 48.0)
		panel.add_child(icon)
		skill_icons.append(icon)

		var cooldown_overlay := ColorRect.new()
		cooldown_overlay.name = "CooldownOverlay"
		cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		cooldown_overlay.color = Color(0.01, 0.02, 0.025, 0.72)
		cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown_overlay.hide()
		panel.add_child(cooldown_overlay)
		skill_cooldown_overlays.append(cooldown_overlay)

		var cooldown_label := Label.new()
		cooldown_label.name = "CooldownLabel"
		cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_label.add_theme_font_size_override("font_size", 20)
		cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.56, 1.0))
		cooldown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
		cooldown_label.add_theme_constant_override("shadow_offset_x", 2)
		cooldown_label.add_theme_constant_override("shadow_offset_y", 2)
		cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown_label.hide()
		panel.add_child(cooldown_label)
		skill_cooldown_labels.append(cooldown_label)

	if RESERVE_SKILL_SLOT_COUNT <= 0:
		return

	var switch_panel := Panel.new()
	switch_panel.name = "SkillSwitchHint"
	switch_panel.position = Vector2(207.0, 45.0)
	switch_panel.size = Vector2(28.0, 28.0)
	switch_panel.add_theme_stylebox_override("panel", _round_style(Color(0.018, 0.024, 0.03, 0.82), Color(0.72, 0.9, 0.94, 0.82), 2, 14))
	switch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_hud.add_child(switch_panel)

	var switch_label := Label.new()
	switch_label.text = "R"
	switch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
	switch_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
	switch_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	switch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	switch_label.add_theme_font_size_override("font_size", 13)
	switch_label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 0.95))
	switch_panel.add_child(switch_label)


func _connect_game_state() -> void:
	if not GameState.health_potions_changed.is_connected(_on_health_potions_changed):
		GameState.health_potions_changed.connect(_on_health_potions_changed)
	if not GameState.equipped_skills_changed.is_connected(_on_equipped_skills_changed):
		GameState.equipped_skills_changed.connect(_on_equipped_skills_changed)
	if not GameState.active_skill_group_changed.is_connected(_on_active_skill_group_changed):
		GameState.active_skill_group_changed.connect(_on_active_skill_group_changed)
	if not GameState.ultimate_charge_changed.is_connected(_on_ultimate_charge_changed):
		GameState.ultimate_charge_changed.connect(_on_ultimate_charge_changed)


func _connect_player() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("stamina_changed") and not player.stamina_changed.is_connected(_on_stamina_changed):
		player.stamina_changed.connect(_on_stamina_changed)
	if player.has_signal("respawned") and not player.respawned.is_connected(_on_player_respawned):
		player.respawned.connect(_on_player_respawned)
	if player.has_signal("far_attack_cooldown_changed") and not player.far_attack_cooldown_changed.is_connected(_on_far_attack_cooldown_changed):
		player.far_attack_cooldown_changed.connect(_on_far_attack_cooldown_changed)
	if player.get("current_health") != null and player.get("max_health") != null:
		_on_health_changed(float(player.get("current_health")), int(player.get("max_health")))
	if player.get("current_stamina") != null and player.get("max_stamina") != null:
		_on_stamina_changed(float(player.get("current_stamina")), float(player.get("max_stamina")))
	if player.get("far_attack_cooldown_left") != null and player.get("far_attack_cooldown") != null:
		_on_far_attack_cooldown_changed(float(player.get("far_attack_cooldown_left")), float(player.get("far_attack_cooldown")))


func _on_health_changed(current_health: float, max_health: int) -> void:
	var ratio := 1.0 if max_health <= 0 else clampf(current_health / float(max_health), 0.0, 1.0)
	var fill_width := HEALTH_FILL_SIZE.x * ratio
	var last_chance := current_health > 0.0 and current_health <= 1.0
	health_fill.visible = current_health > 0.0
	health_fill.color = Color(1.0, 0.16, 0.12, 0.98) if last_chance else Color(0.96, 0.27, 0.43, 0.95)
	health_fill.polygon = _health_bar_points(fill_width, last_chance)


func _on_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	var ratio := 1.0 if max_stamina <= 0.0 else clampf(current_stamina / max_stamina, 0.0, 1.0)
	stamina_fill.size.x = STAMINA_FILL_SIZE.x * ratio
	stamina_fill.color = Color(1.0, 0.48, 0.06, 0.95) if ratio < 0.22 else Color(1.0, 0.82, 0.08, 0.98)


func _on_health_potions_changed(amount: int) -> void:
	for i in range(potion_fills.size()):
		potion_fills[i].color = Color(0.95, 0.16, 0.32, 0.95) if i < amount else Color(0.13, 0.16, 0.17, 0.42)


func _on_player_respawned() -> void:
	_on_health_potions_changed(GameState.get_health_potion_count())
	_on_far_attack_cooldown_changed(0.0, 1.0)


func _on_far_attack_cooldown_changed(time_left: float, max_time: float) -> void:
	if skill_cooldown_overlays.is_empty() or skill_cooldown_labels.is_empty():
		return
	var overlay := skill_cooldown_overlays[0]
	var label := skill_cooldown_labels[0]
	if time_left <= 0.05 or max_time <= 0.0:
		overlay.hide()
		label.hide()
		return
	var ratio := clampf(time_left / max_time, 0.0, 1.0)
	overlay.show()
	overlay.position = Vector2(0.0, 66.0 * (1.0 - ratio))
	overlay.size = Vector2(66.0, 66.0 * ratio)
	label.text = "%.1f" % time_left
	label.show()


func _on_equipped_skills_changed(_paths: Array) -> void:
	_update_skill_icons(false)


func _on_active_skill_group_changed(_group_index: int) -> void:
	_update_skill_icons(true)


func _on_ultimate_charge_changed(current_charge: float, max_charge: float) -> void:
	ultimate_charge_current = current_charge
	ultimate_charge_max = max_charge
	var ratio := 0.0 if max_charge <= 0.0 else clampf(current_charge / max_charge, 0.0, 1.0)
	var fill_height := 86.0 * ratio
	ultimate_fill.position.y = 90.0 - fill_height
	ultimate_fill.size.y = fill_height
	ultimate_fill.color = Color(1.0, 0.82, 0.28, 0.96) if ratio >= 1.0 else Color(0.65, 0.48, 1.0, 0.86)


func _update_active_skill_icons() -> void:
	_update_skill_icons(false)


func _update_skill_icons(animate_swap: bool) -> void:
	var active_paths := GameState.get_active_skill_icons()
	var reserve_paths := _get_reserve_skill_icons()
	_set_skill_icon_group(skill_icons, active_paths, false)
	_set_skill_icon_group(back_skill_icons, reserve_paths, true)
	if animate_swap:
		_play_skill_group_swap_animation()


func _set_skill_icon_group(icons: Array[Sprite2D], paths: Array[String], is_reserve: bool) -> void:
	for i in range(icons.size()):
		var icon := icons[i]
		var path := String(paths[i]) if i < paths.size() else ""
		if path == "":
			icon.texture = SKILL_FALLBACK_TEXTURE
			icon.modulate = Color(0.78, 0.92, 0.96, 0.18 if is_reserve else 0.2)
			_fit_skill_sprite(icon, 38.0 if is_reserve else 48.0)
			continue
		var texture := _load_runtime_texture(path)
		icon.texture = texture if texture is Texture2D else SKILL_FALLBACK_TEXTURE
		icon.modulate = Color(1.0, 1.0, 1.0, 0.48 if is_reserve else 0.94)
		_fit_skill_sprite(icon, 38.0 if is_reserve else 48.0)

	for panel in skill_slot_panels:
		panel.add_theme_stylebox_override("panel", _round_style(Color(0.014, 0.025, 0.032, 0.72), Color(0.75, 0.9, 0.94, 0.74), 2, 33))


func _get_reserve_skill_icons() -> Array[String]:
	var normalized := GameState.equipped_skill_icons.duplicate()
	while normalized.size() < 4:
		normalized.append("")
	var start_index := 2 if GameState.active_skill_group == 0 else 0
	return [String(normalized[start_index]), String(normalized[start_index + 1])]


func _play_skill_group_swap_animation() -> void:
	if skill_swap_tween != null and skill_swap_tween.is_valid():
		skill_swap_tween.kill()
	skill_swap_tween = create_tween()
	skill_swap_tween.set_parallel(true)
	for i in range(skill_slot_panels.size()):
		var front_panel := skill_slot_panels[i]
		var back_panel := back_skill_slot_panels[i]
		front_panel.position = _back_skill_position(i)
		front_panel.scale = Vector2.ONE * 0.86
		front_panel.modulate = Color(0.62, 0.78, 0.82, 0.45)
		back_panel.position = _front_skill_position(i)
		back_panel.scale = Vector2.ONE
		back_panel.modulate = Color.WHITE
		skill_swap_tween.tween_property(front_panel, "position", _front_skill_position(i), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		skill_swap_tween.tween_property(front_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		skill_swap_tween.tween_property(front_panel, "modulate", Color.WHITE, 0.18)
		skill_swap_tween.tween_property(back_panel, "position", _back_skill_position(i), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		skill_swap_tween.tween_property(back_panel, "scale", Vector2.ONE * 0.86, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		skill_swap_tween.tween_property(back_panel, "modulate", Color(0.62, 0.78, 0.82, 0.45), 0.18)


func _front_skill_position(index: int) -> Vector2:
	return Vector2(48.0 + float(index) * 78.0, 24.0)


func _back_skill_position(index: int) -> Vector2:
	return _front_skill_position(index) + Vector2(18.0, -18.0)


func _diamond_points(center: Vector2, radius: float) -> PackedVector2Array:
	var half_height := radius * POTION_DIAMOND_HEIGHT_SCALE
	return PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, half_height),
		center + Vector2(-radius, 0.0),
	])


func _health_bar_points(fill_width: float, last_chance: bool) -> PackedVector2Array:
	var width := fill_width
	width = clampf(width, 0.0, HEALTH_FILL_SIZE.x)
	var left := HEALTH_FILL_POS.x
	var right := HEALTH_FILL_POS.x + width
	var top := HEALTH_FILL_POS.y
	var bottom := HEALTH_FILL_POS.y + HEALTH_FILL_SIZE.y
	if last_chance:
		return PackedVector2Array([
			Vector2(left, top),
			Vector2(left + LAST_HEALTH_SPIKE_PEAK, bottom - LAST_HEALTH_SPIKE_INSET),
			Vector2(left + LAST_HEALTH_SPIKE_START, bottom),
			Vector2(left, bottom),
		])
	if width <= 0.0:
		return PackedVector2Array()
	if width <= LAST_HEALTH_SPIKE_START:
		return PackedVector2Array([
			Vector2(left, top),
			Vector2(right, top),
			Vector2(right, bottom),
			Vector2(left, bottom),
		])
	return PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left + LAST_HEALTH_SPIKE_END, bottom),
		Vector2(left + LAST_HEALTH_SPIKE_PEAK, bottom - LAST_HEALTH_SPIKE_INSET),
		Vector2(left + LAST_HEALTH_SPIKE_START, bottom),
		Vector2(left, bottom),
	])


func _round_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _flat_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	return style


func _fit_skill_sprite(sprite: Sprite2D, target_size: float = 48.0) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	var longest_side := maxf(texture_size.x, texture_size.y)
	if longest_side <= 0.0:
		return
	sprite.scale = Vector2.ONE * (target_size / longest_side)


func _load_runtime_texture(path: String) -> Texture2D:
	if path.to_lower().ends_with(".png"):
		var source_image := Image.new()
		if source_image.load(ProjectSettings.globalize_path(path)) == OK:
			return ImageTexture.create_from_image(source_image)
	var resource := load(path)
	if resource is Texture2D:
		return resource
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	return ImageTexture.create_from_image(image)
