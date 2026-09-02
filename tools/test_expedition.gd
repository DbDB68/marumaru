extends SceneTree
## 远征番茄钟单元测试：派出/倒计时/到点完成/取消/离线补报
## 用法：godot --headless --path <项目> --script res://tools/test_expedition.gd

var _failures := 0
const TEST_SAVE := "user://test_expedition.json"


func _init() -> void:
	var E: Node = load("res://scripts/expedition.gd").new()
	E.save_path = TEST_SAVE
	root.add_child(E)
	await process_frame

	# --- 派出 ---
	var got_started := [false]
	E.started.connect(func() -> void: got_started[0] = true)
	E.start(25)
	_check(got_started[0], "派出时应发 started 信号")
	_check(E.is_active(), "派出后应处于远征中")
	_check(E.is_away("hasebe"), "远征中长谷部应不在家")
	var remain: int = E.remaining_seconds()
	_check(remain > 1480 and remain <= 1500, "25 分钟倒计时应≈1500s (实际 %d)" % remain)

	# --- 到点完成 ---
	var got_finished := [false]
	E.finished.connect(func() -> void: got_finished[0] = true)
	E._end_unix = Time.get_unix_time_from_system() - 1.0  # 假装时间已到
	await process_frame
	await process_frame
	_check(got_finished[0], "到点应发 finished 信号")
	_check(E.has_pending_report(), "到点后应有待报告的归队")
	_check(not E.is_active(), "到点后不再是远征中")

	# --- 离线补报：新实例读档后仍记得要报告 ---
	var E2: Node = load("res://scripts/expedition.gd").new()
	E2.save_path = TEST_SAVE
	root.add_child(E2)
	await process_frame
	_check(E2.has_pending_report(), "重开游戏应记得有待报告的归队（离线结算）")
	root.remove_child(E2)
	E2.queue_free()

	# --- 取消 ---
	E.start(45)
	_check(E.is_active(), "重新派出应处于远征中")
	E.cancel()
	_check(not E.is_active() and not E.has_pending_report(), "取消后应回归闲置")

	root.remove_child(E)
	E.queue_free()
	DirAccess.remove_absolute(TEST_SAVE)

	if _failures == 0:
		print("EXPEDITION TEST: all OK")
	else:
		push_error("EXPEDITION TEST: %d 项失败" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
