extends Node
## 场景切换回归测试：加载主屋 → 传送主角踩门 → 验证切到庭院且落点正确
## 用法：godot --headless --path <项目> res://tools/test_switch.tscn
## 注意：本节点会把自己挪到场景树根下，免得换场景时被一起释放

func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout

	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "主屋加载后应能找到主角")

	# 日程生成检查：每个刀男此时刻该在哪个房间，就该出现在哪
	for id in Schedule.all_npc_ids():
		var slot := Schedule.current_slot(id)
		var npc := _find_npc(id)
		if slot.get("room") == "main":
			_check(npc != null, "%s 日程=%s(%s)，应出现在主屋" % [id, slot.get("activity"), slot.get("from")])
		else:
			_check(npc == null, "%s 日程=%s(%s) 在 %s，不应出现在主屋" % [id, slot.get("activity"), slot.get("from"), slot.get("room")])

	# 传送到主屋门口触发切换
	player.global_position = Vector2(480, 524)
	await get_tree().create_timer(1.5).timeout

	var cur := get_tree().current_scene
	_check(cur != null and cur.name == "Courtyard", "踩门后应切换到庭院 (当前: %s)" % (cur.name if cur else "null"))
	var p2 := get_tree().get_first_node_in_group("player")
	_check(p2 != null and p2.global_position.distance_to(Vector2(480, 80)) < 1.0,
		"切换后主角应在庭院出生点 (实际: %s)" % (p2.global_position if p2 else "null"))

	# 庭院侧的日程生成检查
	for id in Schedule.all_npc_ids():
		var slot2 := Schedule.current_slot(id)
		var npc2 := _find_npc(id)
		if slot2.get("room") == "courtyard":
			_check(npc2 != null, "%s 日程=%s(%s)，应出现在庭院" % [id, slot2.get("activity"), slot2.get("from")])
		else:
			_check(npc2 == null, "%s 日程=%s(%s) 在 %s，不应出现在庭院" % [id, slot2.get("activity"), slot2.get("from"), slot2.get("room")])

	# 再踩庭院的门回主屋
	p2.global_position = Vector2(480, 16)
	await get_tree().create_timer(1.5).timeout
	cur = get_tree().current_scene
	_check(cur != null and cur.name == "Main", "踩庭院的门应回到主屋 (当前: %s)" % (cur.name if cur else "null"))
	var p3 := get_tree().get_first_node_in_group("player")
	_check(p3 != null and p3.global_position.distance_to(Vector2(480, 480)) < 1.0,
		"回来后主角应在主屋出生点 (实际: %s)" % (p3.global_position if p3 else "null"))

	print("SWITCH TEST: done")
	get_tree().quit()


var _failures := 0


func _find_npc(npc_id: String) -> Node2D:
	for n in get_tree().get_nodes_in_group("npcs"):
		if n.npc_id == npc_id:
			return n
	return null


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
