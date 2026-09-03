extends SceneTree
## 双人小剧场单元测试：interactions.json 数据完整性 + 组合确实有机会同处一室
## 用法：godot --headless --path <项目> --script res://tools/test_banter.gd

var _failures := 0


func _init() -> void:
	var Banter := load("res://scripts/banter.gd")
	var pairs: Dictionary = Banter._load_data()
	_check(not pairs.is_empty(), "interactions.json 应能读出组合")

	var npc_ids: Array = Schedule.all_npc_ids()
	for key in pairs:
		var ids: PackedStringArray = str(key).split("+")
		_check(ids.size() == 2, "组合键 %s 应为 id1+id2" % key)
		if ids.size() != 2:
			continue
		_check(ids[0] < ids[1], "组合键 %s 应按字典序排列" % key)
		_check(npc_ids.has(ids[0]) and npc_ids.has(ids[1]),
			"组合 %s 的两位都应在日程表里" % key)

		# 对白结构：每段非空，who 必须是组合的两位之一，text 非空
		var scripts: Array = pairs[key]
		_check(not scripts.is_empty(), "组合 %s 至少有一段对白" % key)
		for script in scripts:
			_check(script is Array and not script.is_empty(), "%s 的对白段应非空" % key)
			for line in script:
				_check(str(line.get("who", "")) in [ids[0], ids[1]],
					"%s 的说话人 %s 应在组合内" % [key, line.get("who", "?")])
				_check(not str(line.get("text", "")).is_empty(),
					"%s 的台词不应为空" % key)

		# 两人在一天里总得有机会同处一室，否则对白永远不会触发
		var overlap := false
		for hour in range(24):
			for half in [0, 30]:
				var room_a: String = Schedule.current_slot(ids[0], hour, half).get("room", "")
				var room_b: String = Schedule.current_slot(ids[1], hour, half).get("room", "")
				if room_a != "" and room_a == room_b:
					overlap = true
		_check(overlap, "组合 %s 一天内应有同房间的时段" % key)

		# 对应 NPC 场景文件得存在
		for id in ids:
			_check(ResourceLoader.exists("res://scenes/npcs/%s.tscn" % id),
				"刀男场景应存在: scenes/npcs/%s.tscn" % id)

	if _failures == 0:
		print("BANTER TEST: all OK")
	else:
		push_error("BANTER TEST: %d 项失败" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
