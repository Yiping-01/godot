extends RefCounted
class_name DemoMenuUiArt

const UI_ROOT := "res://demo/assets/generated/exhibition_ui/menu/"

const MAIN_BUTTON_NORMAL := UI_ROOT + "main_button_normal.png"
const MAIN_BUTTON_HOVER := UI_ROOT + "main_button_hover.png"
const MAIN_BUTTON_PRESSED := UI_ROOT + "main_button_pressed.png"
const SMALL_BUTTON_NORMAL := UI_ROOT + "small_button_normal.png"
const SMALL_BUTTON_HOVER := UI_ROOT + "small_button_hover.png"
const PAUSE_PANEL := UI_ROOT + "pause_panel_frame.png"
const SETTINGS_PANEL := UI_ROOT + "settings_panel_frame.png"
const SAVE_PANEL := UI_ROOT + "save_panel_frame.png"
const INVENTORY_PANEL := "res://demo/assets/generated/exhibition_ui/inventory_panel_frame.png"


static func main_button_style(state := "normal") -> StyleBox:
	var path := MAIN_BUTTON_NORMAL
	if state == "hover" or state == "focus":
		path = MAIN_BUTTON_HOVER
	elif state == "pressed":
		path = MAIN_BUTTON_PRESSED
	return _texture_style(path, 64, 34, 64, 34, Vector2(18.0, 8.0), _flat_button(state, false))


static func small_button_style(state := "normal") -> StyleBox:
	var path := SMALL_BUTTON_HOVER if state == "hover" or state == "focus" or state == "pressed" else SMALL_BUTTON_NORMAL
	return _texture_style(path, 40, 28, 40, 28, Vector2(14.0, 7.0), _flat_button(state, true))


static func panel_style(kind := "settings") -> StyleBox:
	var path := SETTINGS_PANEL
	var margins := Vector4(58, 58, 58, 58)
	var content := Vector2(22.0, 18.0)
	if kind == "pause":
		path = PAUSE_PANEL
		margins = Vector4(70, 70, 70, 70)
		content = Vector2(28.0, 24.0)
	elif kind == "save":
		path = SAVE_PANEL
		margins = Vector4(64, 56, 64, 56)
		content = Vector2(26.0, 22.0)
	return _texture_style(path, int(margins.x), int(margins.y), int(margins.z), int(margins.w), content, _flat_panel(kind))


static func inventory_panel_style() -> StyleBox:
	return _texture_style(INVENTORY_PANEL, 52, 52, 52, 52, Vector2(34.0, 24.0), _flat_panel("inventory"))


static func _texture_style(path: String, left: int, top: int, right: int, bottom: int, content: Vector2, fallback: StyleBox) -> StyleBox:
	var texture := _load_texture(path)
	if not texture is Texture2D:
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = left
	style.texture_margin_top = top
	style.texture_margin_right = right
	style.texture_margin_bottom = bottom
	style.content_margin_left = content.x
	style.content_margin_right = content.x
	style.content_margin_top = content.y
	style.content_margin_bottom = content.y
	return style


static func _load_texture(path: String) -> Texture2D:
	var resource := load(path)
	if resource is Texture2D:
		return resource
	if path.to_lower().ends_with(".png"):
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(path)) == OK:
			return ImageTexture.create_from_image(image)
	return null


static func _flat_button(state: String, small: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if state == "pressed":
		style.bg_color = Color(0.12, 0.1, 0.04, 0.92)
		style.border_color = Color(1.0, 0.76, 0.28, 0.78)
	elif state == "hover" or state == "focus":
		style.bg_color = Color(0.06, 0.11, 0.13, 0.9)
		style.border_color = Color(0.68, 0.9, 0.95, 0.68)
	else:
		style.bg_color = Color(0.025, 0.05, 0.06, 0.82)
		style.border_color = Color(0.42, 0.68, 0.72, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14.0 if small else 18.0
	style.content_margin_right = 14.0 if small else 18.0
	style.content_margin_top = 7.0 if small else 8.0
	style.content_margin_bottom = 7.0 if small else 8.0
	return style


static func _flat_panel(kind: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.024, 0.03, 0.94)
	style.border_color = Color(0.52, 0.78, 0.82, 0.42)
	if kind == "save":
		style.bg_color = Color(0.015, 0.03, 0.038, 0.94)
		style.border_color = Color(0.56, 0.82, 0.84, 0.46)
	elif kind == "inventory":
		style.bg_color = Color(0.008, 0.043, 0.052, 1.0)
		style.border_color = Color(0.46, 0.68, 0.66, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style
