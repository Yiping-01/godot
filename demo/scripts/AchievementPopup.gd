extends CanvasLayer

@onready var panel: PanelContainer = $Root/Panel
@onready var title_label: Label = $Root/Panel/Margin/Content/TitleLabel
@onready var description_label: Label = $Root/Panel/Margin/Content/DescriptionLabel

var popup_tween: Tween
var queue: Array[Dictionary] = []
var showing := false
var panel_base_position := Vector2.ZERO


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel_base_position = panel.position
	panel.modulate.a = 0.0
	panel.position = panel_base_position + Vector2(380.0, 0.0)
	var manager := get_node_or_null("/root/AchievementManager")
	if manager != null and manager.has_signal("achievement_unlocked"):
		manager.connect("achievement_unlocked", Callable(self, "show_achievement"))


func show_achievement(title: String, description: String) -> void:
	queue.append({
		"title": title,
		"description": description,
	})
	if not showing:
		_play_next()


func _play_next() -> void:
	if queue.is_empty():
		showing = false
		return

	showing = true
	var data: Dictionary = queue.pop_front() as Dictionary
	title_label.text = String(data["title"])
	description_label.text = String(data["description"])

	if popup_tween != null:
		popup_tween.kill()

	panel.modulate.a = 0.0
	panel.position = panel_base_position + Vector2(380.0, 0.0)
	popup_tween = create_tween()
	popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	popup_tween.tween_property(panel, "position:x", panel_base_position.x, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	popup_tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)
	popup_tween.tween_interval(2.5)
	popup_tween.tween_property(panel, "position:x", panel_base_position.x + 380.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	popup_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.2)
	await popup_tween.finished
	_play_next()
