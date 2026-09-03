extends Node
## 小剧场实况冒烟测试：把两位刀男摆到一起，等首轮检查，应触发搭话
## 用法：godot --headless --path <项目> res://tools/test_banter_live.tscn
## 注意：本节点会把自己挪到场景树根下，免得换场景时被一起释放

var _failures := 0


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout

	# 不依赖当前时刻的日程：直接把两位生成出来摆到一起钉住
	var a: Node2D = load("res://scenes/npcs/hasebe.tscn").instantiate()
	a.npc_id = "hasebe"
	var b: Node2D = load("res://scenes/npcs/fudou.tscn").instantiate()
	b.npc_id = "fudou"
	get_tree().current_scene.add_child(a)
	get_tree().current_scene.add_child(b)
	for n in [a, b]:
		n.global_position = Vector2(480, 300)
		n._home = n.global_position
		n._idle_left = 999.0  # 钉住不许溜达
	a.global_position.x -= 40

	# banter 首轮检查在 8 秒左右，等对白发车
	await get_tree().create_timer(11.0).timeout
	_check(a._bantering or b._bantering, "两位靠近后应触发小剧场搭话")

	print("BANTER LIVE TEST: done")
	get_tree().quit(1 if _failures > 0 else 0)


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
