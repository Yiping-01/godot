extends Node

signal achievement_unlocked(title: String, description: String)

var unlocked_achievements := {}
var monster_names := {
	"NormalOctopus": "小耳朵章魚",
	"DashSquid": "透抽章魚",
	"SlamSquid": "花枝章魚",
	"WaterBlueBounceOctopus": "螢幕保護章魚",
	"Boss": "巨型章魚怪",
}


func unlock_kill_achievement(monster_id: String) -> void:
	monster_id = monster_id.strip_edges()
	if monster_id == "":
		return
	if unlocked_achievements.has(monster_id):
		return

	unlocked_achievements[monster_id] = true
	var monster_name := String(monster_names.get(monster_id, monster_id))
	achievement_unlocked.emit("成就解鎖", "第一次擊殺：%s" % monster_name)
