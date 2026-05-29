extends SceneTree

const PLAYER_BODY_COLLISION_LAYER_NUMBER := 2
const ENEMY_BODY_COLLISION_LAYER_NUMBER := 3


class DamageProbeArea:
	extends Area2D

	var damage_taken := 0

	func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
		damage_taken += amount


class DamageProbeBody:
	extends CharacterBody2D

	var damage_taken := 0

	func _init() -> void:
		add_to_group("player")

	func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
		damage_taken += amount


var failures: Array[String] = []
var has_run := false


func _init() -> void:
	call_deferred("_run_once")


func _initialize() -> void:
	call_deferred("_run_once")


func _run_once() -> void:
	if has_run:
		return

	has_run = true
	_run()


func _run() -> void:
	_check_player_collision_rule()
	_check_enemy_collision_rules()
	_check_attack_window_rules()
	_check_damage_application_rules()

	if failures.is_empty():
		print("combat_rules_check: OK")
		_write_result("OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_write_result("FAILED\n" + "\n".join(failures))
	quit(1)


func _check_player_collision_rule() -> void:
	var player := _instantiate("res://demo/scenes/player.tscn")
	if player == null:
		return

	_expect(
		not player.get_collision_mask_value(ENEMY_BODY_COLLISION_LAYER_NUMBER),
		"Player should ignore enemy body collision by default."
	)
	player.queue_free()


func _check_enemy_collision_rules() -> void:
	var scenes := [
		"res://demo/scenes/enemy.tscn",
		"res://demo/scenes/enemy2.tscn",
		"res://demo/scenes/squid_monster.tscn",
		"res://demo/scenes/legacy_split_enemy.tscn",
		"res://demo/scenes/blue_bounce_split_enemy.tscn",
		"res://demo/scenes/blue_bounce_small_enemy.tscn",
	]

	for scene_path in scenes:
		var enemy := _instantiate(scene_path)
		if enemy == null:
			continue
		_expect(
			not enemy.get_collision_mask_value(PLAYER_BODY_COLLISION_LAYER_NUMBER),
			"%s should ignore player body collision by default." % scene_path
		)
		enemy.queue_free()


func _check_attack_window_rules() -> void:
	var squid := _instantiate("res://demo/scenes/squid_monster.tscn")
	if squid != null:
		squid.state = 1
		_expect(not squid.call("can_receive_player_attack"), "Squid should reject hits while moving above the player.")
		squid.state = 2
		_expect(not squid.call("can_receive_player_attack"), "Squid should reject hits during slam windup.")
		squid.state = 3
		_expect(bool(squid.call("can_receive_player_attack")), "Squid should become hittable during slam active/recovery windows.")
		_expect(bool(squid.call("_is_contact_damage_active")), "Squid contact damage should only be active during the slam.")
		squid.state = 4
		_expect(not bool(squid.call("_is_contact_damage_active")), "Squid contact damage should turn off after the slam.")
		squid.queue_free()

	var dash_squid := _instantiate("res://demo/scenes/enemy2.tscn")
	if dash_squid != null:
		dash_squid.state = &"idle"
		_expect(not bool(dash_squid.call("_is_contact_damage_active")), "DashSquid contact damage should be off while idle.")
		dash_squid.state = &"windup"
		_expect(not bool(dash_squid.call("_is_contact_damage_active")), "DashSquid contact damage should be off during windup.")
		dash_squid.state = &"dash"
		_expect(bool(dash_squid.call("_is_contact_damage_active")), "DashSquid contact damage should be active during dash.")
		dash_squid.state = &"recovery"
		_expect(not bool(dash_squid.call("_is_contact_damage_active")), "DashSquid contact damage should be off during recovery.")
		dash_squid.queue_free()

	var boss_level := _instantiate("res://demo/scenes/levels/demo_boss.tscn")
	var boss := boss_level.get_node_or_null("Boss") if boss_level != null else null
	if boss != null:
		boss.state = &"idle"
		_expect(bool(boss.call("_is_body_contact_damage_active")), "Boss body contact damage should be active while idle.")
		boss.state = &"windup"
		_expect(bool(boss.call("_is_body_contact_damage_active")), "Boss body contact damage should be active during windup.")
		boss.state = &"dash"
		_expect(bool(boss.call("_is_body_contact_damage_active")), "Boss body contact damage should be active during dash.")
		boss.state = &"quake_jump"
		boss.velocity.y = -100.0
		_expect(not bool(boss.call("can_receive_player_attack")), "Boss should reject player hits while rising in quake_jump.")
		_expect(bool(boss.call("_is_body_contact_damage_active")), "Boss body contact damage should be active while rising.")
		boss.velocity.y = 100.0
		_expect(bool(boss.call("can_receive_player_attack")), "Boss should become hittable while falling in quake_jump.")
		_expect(bool(boss.call("_is_body_contact_damage_active")), "Boss body contact damage should be active while falling.")
	if boss_level != null:
		boss_level.queue_free()


func _check_damage_application_rules() -> void:
	_check_area_contact_damage(
		"res://demo/scenes/squid_monster.tscn",
		"state",
		[1, 2, 4, 5],
		3,
		"_damage_contact_target",
		"Squid contact damage"
	)
	_check_area_contact_damage(
		"res://demo/scenes/enemy2.tscn",
		"state",
		[&"idle", &"windup", &"recovery"],
		&"dash",
		"_damage_contact_target",
		"DashSquid contact damage"
	)
	_check_area_contact_damage(
		"res://demo/scenes/enemy.tscn",
		"state",
		[&"patrol", &"attack_windup", &"attack_recovery"],
		&"attack",
		"_damage_attack_target",
		"Normal enemy attack damage"
	)
	_check_body_contact_damage(
		"res://demo/scenes/legacy_split_enemy.tscn",
		"state",
		[&"patrol", &"attack_windup", &"attack_recovery"],
		&"attack",
		"_damage_attack_body",
		"Legacy split enemy body damage"
	)
	_check_body_contact_damage(
		"res://demo/scenes/blue_bounce_split_enemy.tscn",
		"state",
		[&"pulse_idle", &"pulse_windup", &"pulse_recovery"],
		&"attack",
		"_damage_attack_body",
		"Blue bounce split enemy body damage"
	)
	_check_area_contact_damage(
		"res://demo/scenes/blue_bounce_small_enemy.tscn",
		"state",
		[&"pulse_idle", &"pulse_windup", &"pulse_recovery"],
		&"attack",
		"_damage_attack_target",
		"Blue bounce small enemy damage"
	)

	var boss_level := _instantiate("res://demo/scenes/levels/demo_boss.tscn")
	var boss := boss_level.get_node_or_null("Boss") if boss_level != null else null
	if boss != null:
		var probe := _new_probe_area()
		for contact_state in [&"idle", &"windup", &"recover", &"rest", &"dash"]:
			boss.state = contact_state
			probe.damage_taken = 0
			boss.call("_damage_contact_target", probe)
			_expect(probe.damage_taken > 0, "Boss body contact damage should apply during %s." % contact_state)
		probe.queue_free()
	if boss_level != null:
		boss_level.queue_free()


func _check_area_contact_damage(scene_path: String, state_property: String, inactive_states: Array, active_state, damage_method: StringName, label: String) -> void:
	var enemy := _instantiate(scene_path)
	if enemy == null:
		return

	var probe := _new_probe_area()
	for inactive_state in inactive_states:
		enemy.set(state_property, inactive_state)
		probe.damage_taken = 0
		enemy.call(damage_method, probe)
		_expect(probe.damage_taken == 0, "%s should not apply during %s." % [label, inactive_state])

	enemy.set(state_property, active_state)
	probe.damage_taken = 0
	enemy.call(damage_method, probe)
	_expect(probe.damage_taken > 0, "%s should apply during %s." % [label, active_state])

	probe.queue_free()
	enemy.queue_free()


func _check_body_contact_damage(scene_path: String, state_property: String, inactive_states: Array, active_state, damage_method: StringName, label: String) -> void:
	var enemy := _instantiate(scene_path)
	if enemy == null:
		return

	var probe := _new_probe_body()
	for inactive_state in inactive_states:
		enemy.set(state_property, inactive_state)
		probe.damage_taken = 0
		enemy.call(damage_method, probe)
		_expect(probe.damage_taken == 0, "%s should not apply during %s." % [label, inactive_state])

	enemy.set(state_property, active_state)
	probe.damage_taken = 0
	enemy.call(damage_method, probe)
	_expect(probe.damage_taken > 0, "%s should apply during %s." % [label, active_state])

	probe.queue_free()
	enemy.queue_free()


func _instantiate(scene_path: String) -> Node:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		failures.append("Could not load %s." % scene_path)
		return null

	var instance := scene.instantiate()
	root.add_child(instance)
	return instance


func _new_probe_area() -> DamageProbeArea:
	var probe := DamageProbeArea.new()
	root.add_child(probe)
	return probe


func _new_probe_body() -> DamageProbeBody:
	var probe := DamageProbeBody.new()
	root.add_child(probe)
	return probe


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _write_result(text: String) -> void:
	var result_path := OS.get_environment("COMBAT_RULES_RESULT_PATH")
	if result_path.is_empty():
		result_path = "user://combat_rules_check_result.txt"

	var file := FileAccess.open(result_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write combat rules result to %s." % result_path)
		return
	file.store_string(text)
