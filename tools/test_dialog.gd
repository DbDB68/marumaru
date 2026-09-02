extends SceneTree
## 对话框回归测试：模拟 Z 键操作，验证「打字 → 跳过 → 翻页 → 关闭」全流程
## 用法：godot --headless --path <项目> --script res://tools/test_dialog.gd

var _failures := 0


func _init() -> void:
	var dialog = load("res://scenes/dialog_box.tscn").instantiate()
	root.add_child(dialog)
	await process_frame  # 等 _ready 把节点接好

	# --- 场景 1：跳过打字 → 再按 Z 必须能关闭（本次修复的 bug）---
	dialog.open(["需要我做什么？无论是泡茶还是……斩人。"])
	_check(dialog.is_open(), "open 后对话框应处于打开状态")
	_press_z(dialog)  # 跳过打字
	_check(dialog.is_open(), "跳过打字后对话框应仍开着")
	_press_z(dialog)  # 关闭
	_check(not dialog.is_open(), "跳过打字后再按 Z 应关闭对话框")

	# --- 场景 2：等打字自然结束 → Z 关闭 ---
	dialog.open(["本丸的警备就交给我吧。"])
	await create_timer(0.04 * 20).timeout  # 足够打完这行字
	_press_z(dialog)
	_check(not dialog.is_open(), "打字自然结束后按 Z 应关闭对话框")

	# --- 场景 3：多句翻页 ---
	dialog.open(["第一句", "第二句"])
	_press_z(dialog)  # 跳过第一句打字
	_press_z(dialog)  # 翻到第二句
	_check(dialog.is_open(), "翻到第二句时应仍开着")
	_press_z(dialog)  # 跳过第二句打字
	_press_z(dialog)  # 关闭
	_check(not dialog.is_open(), "两句都读完应按 Z 关闭")

	# --- 场景 4：Esc 强制关闭 ---
	dialog.open(["压切长谷部，随侍在侧。"])
	var esc := InputEventKey.new()
	# 真实按键事件 keycode 和 physical_keycode 都会填，测试事件要模拟到位
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	dialog._unhandled_input(esc)
	_check(not dialog.is_open(), "Esc 应随时强制关闭对话框")

	if _failures == 0:
		print("DIALOG TEST: all OK")
	else:
		push_error("DIALOG TEST: %d 项失败" % _failures)
	quit(1 if _failures > 0 else 0)


func _press_z(dialog: Node) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_Z
	ev.pressed = true
	dialog._unhandled_input(ev)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
