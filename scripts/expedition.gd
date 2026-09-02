extends Node
## 远征番茄钟（Autoload: Expedition）
## 派出刀男 → 现实时间倒计时 → 到点弹「远征部队回来了！」
## 状态存 user://expedition.json，关掉游戏也照算，下次打开补报

signal started
signal finished

var save_path := "user://expedition.json"

var _end_unix := 0.0        # 0 = 无远征
var _pending_report := false  # 已完成但还没向玩家报告
var _panel: CanvasLayer


func _ready() -> void:
	_load()
	_panel = load("res://scenes/expedition_panel.tscn").instantiate()
	add_child(_panel)
	if _pending_report:
		_announce.call_deferred()


## 派出远征，duration_min 分钟后回来
func start(duration_min: int) -> void:
	_end_unix = Time.get_unix_time_from_system() + duration_min * 60.0
	_pending_report = false
	_save()
	started.emit()
	_panel.close()


func cancel() -> void:
	_end_unix = 0.0
	_pending_report = false
	_save()


func is_active() -> bool:
	return _end_unix > 0.0 and remaining_seconds() > 0


## 刀男是否因远征不在本丸（目前全队一起走）
func is_away(_npc_id: String) -> bool:
	return is_active()


func remaining_seconds() -> int:
	return maxi(0, int(_end_unix - Time.get_unix_time_from_system()))


func has_pending_report() -> bool:
	return _pending_report


func _process(_delta: float) -> void:
	if _end_unix > 0.0 and remaining_seconds() <= 0:
		_end_unix = 0.0
		_pending_report = true
		_save()
		finished.emit()
		_announce()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_echo():
		return
	if event.is_action_pressed("expedition_menu"):
		_panel.toggle()
		get_viewport().set_input_as_handled()


## 弹「回来了」对话；对话框还没就位就下一帧再试
func _announce() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var d := tree.get_first_node_in_group("dialog_box")
	if d == null:
		await tree.process_frame
		_announce()
		return
	d.open(["远征部队回来了！", "辛苦了。……这是这次的收获。（占位）"])
	_pending_report = false
	_save()


func _save() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"end_unix": _end_unix, "pending_report": _pending_report}))


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		_end_unix = float(parsed.get("end_unix", 0.0))
		_pending_report = bool(parsed.get("pending_report", false))
