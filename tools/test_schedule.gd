extends SceneTree
## 日程表单元测试：验证时段查询、跨午夜回卷、字段完整性
## 用法：godot --headless --path <项目> --script res://tools/test_schedule.gd

var _failures := 0


func _init() -> void:
	# 时段命中
	_check(Schedule.current_slot("hasebe", 7, 0).get("activity") == "晨练", "07:00 应在晨练")
	_check(Schedule.current_slot("hasebe", 11, 59).get("activity") == "打扫", "11:59 应仍在打扫")
	_check(Schedule.current_slot("hasebe", 12, 0).get("activity") == "午饭", "12:00 整点切换到午饭")
	_check(Schedule.current_slot("hasebe", 14, 30).get("activity") == "巡逻", "14:30 应在巡逻")
	_check(Schedule.current_slot("hasebe", 22, 0).get("activity") == "夜间警备", "22:00 应在夜间警备")

	# 跨午夜回卷：凌晨 2 点应沿用 23:00 的休息
	_check(Schedule.current_slot("hasebe", 2, 0).get("activity") == "休息", "凌晨 02:00 应沿用休息")
	_check(Schedule.current_slot("hasebe", 5, 59).get("activity") == "休息", "05:59 应仍在休息")

	# 字段完整性：每个槽位必须有房间和坐标
	var ids := Schedule.all_npc_ids()
	_check(ids.has("hasebe"), "日程表里应有 hasebe")
	for id in ids:
		for e in Schedule._data()[id]:
			_check(e.has("room") and e.has("pos") and e.has("from"),
				"%s 的槽位 %s 字段完整" % [id, e.get("from", "?")])

	# 查无此人
	_check(Schedule.current_slot("不存在的刀", 10, 0).is_empty(), "查无此人应返回空")

	if _failures == 0:
		print("SCHEDULE TEST: all OK")
	else:
		push_error("SCHEDULE TEST: %d 项失败" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
