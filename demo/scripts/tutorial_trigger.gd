extends Area2D
class_name TutorialTrigger

@export_multiline var tutorial_text := "探索這座海底遺跡。觀察敵人的預備動作，再出手。"
@export var enabled := true
@export var display_time := 2.8
@export var one_shot := true
@export var hide_when_exit := true

var triggered := false


func _ready() -> void:
	match name:
		"MoveTutorial":
			tutorial_text = "A / D 或方向鍵移動，Z 跳躍。短按可小跳，長按可跳得更高。"
			display_time = maxf(display_time, 4.0)
		"JumpTutorial":
			tutorial_text = "Z 跳躍。這版加入了跳躍緩衝，早一點按也能順利起跳。"
			display_time = maxf(display_time, 4.2)
		"DoubleJumpTutorial":
			tutorial_text = "空中再按一次 Z 可二段跳。二段跳會刷新你的空中節奏，適合銜接攻擊。"
			display_time = maxf(display_time, 4.2)
		"WallTutorial":
			tutorial_text = "貼住發亮牆面時按住方向可滑牆。按 Z 蹬牆跳，按 C 衝刺穿過危險空隙。"
			display_time = maxf(display_time, 4.0)
		"WallJumpTutorial":
			tutorial_text = "貼住牆面時按方向可滑牆。按 Z 蹬牆跳，落地前可接 C 衝刺。"
			display_time = maxf(display_time, 4.8)
		"WaterTutorial":
			tutorial_text = "水中可用方向鍵游動。C 水中衝刺，F 發射水波，長按 F 可釋放蓄力技能。"
			display_time = maxf(display_time, 4.0)
		"CombatTutorial":
			tutorial_text = "X 近戰攻擊。按住 W 或 S 可改變攻擊方向；空中向下攻擊命中會反彈。"
			display_time = maxf(display_time, 4.6)
		"NormalOctopusTutorial":
			tutorial_text = "敵人發光或壓低身體時代表準備攻擊。等牠出手後再反擊，命中會累積能量。"
			display_time = maxf(display_time, 4.6)
		"DashSquidTutorial":
			tutorial_text = "衝刺怪會先停住、亮出攻擊線，再高速突進。看見預警線就跳開或衝刺閃避。"
			display_time = maxf(display_time, 4.8)
		"SlamSquidTutorial":
			tutorial_text = "下砸怪會先升空再重擊地面。離開落點，等牠落地硬直後進攻。"
			display_time = maxf(display_time, 5.0)
		"BossGateTutorial":
			tutorial_text = "Boss 戰前請在長椅補滿狀態。觀察預備動作，保留衝刺給真正危險的招式。"
			display_time = maxf(display_time, 5.0)
		"MapTutorial":
			tutorial_text = "M 開啟地圖，I 開啟背包與技能。R 可切換目前裝備的技能組。"
			display_time = maxf(display_time, 4.2)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return
	if not is_visible_in_tree():
		return
	if one_shot and triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null:
		if ui.has_method("is_area_title_visible"):
			while is_inside_tree() and ui != null and is_instance_valid(ui) and ui.is_area_title_visible():
				var tree := get_tree()
				if tree == null:
					return
				await tree.process_frame
		if not is_inside_tree() or ui == null or not is_instance_valid(ui):
			return
		ui.show_tutorial(tutorial_text, display_time)


func _on_body_exited(body: Node2D) -> void:
	if not hide_when_exit or not body.is_in_group("player"):
		return

	var ui := get_tree().get_first_node_in_group("game_ui")
	if ui != null and ui.has_method("hide_tutorial"):
		ui.hide_tutorial()
