extends Node
## 刀男双人小剧场（Banter）：同房间的两位刀男靠近时随机搭话，
## 头顶气泡轮番显示，不占用底部对话框、不打断玩家操作。
## 数据在 data/interactions.json：键为按字典序排列的 "id1+id2"，值是若干段对白，
## 每段对白是 [{who, text}, ...] 数组，who 必须是该组合的 id 之一。
## 由 room.gd 在每个房间里实例化。

const DATA_PATH := "res://data/interactions.json"
const FIRST_CHECK := 8.0      # 进屋后第一次检查
const CHECK_MIN := 12.0       # 此后每隔 12~30 秒瞅一眼
const CHECK_MAX := 30.0
const TRIGGER_DIST := 130.0   # 两刀男距离小于这个值才可能开聊
const LINE_SECONDS := 2.2     # 每句气泡停留时长
const COOLDOWN := 60.0        # 聊完一场的冷却

var _pairs: Dictionary = {}
var _check_left := FIRST_CHECK
var _busy := false

var _layer: CanvasLayer
var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_target: Node2D = null


func _ready() -> void:
	_pairs = _load_data()
	_make_bubble()


func _process(delta: float) -> void:
	if _bubble.visible and is_instance_valid(_bubble_target):
		_follow_target()
	if _busy:
		return
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = randf_range(CHECK_MIN, CHECK_MAX)
		_try_start()


static func _load_data() -> Dictionary:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_warning("互动对白读取失败: " + DATA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


func _make_bubble() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.9, 0.95)
	style.border_color = Color(0.29, 0.23, 0.19)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	_bubble.add_theme_stylebox_override("panel", style)
	_bubble_label = Label.new()
	_bubble_label.add_theme_font_size_override("font_size", 13)
	_bubble_label.add_theme_color_override("font_color", Color(0.16, 0.12, 0.1))
	_bubble.add_child(_bubble_label)
	_bubble.hide()
	_layer.add_child(_bubble)


## 气泡跟着说话人头顶走（世界坐标 → 屏幕坐标，含相机与缩放）
func _follow_target() -> void:
	var screen := _bubble_target.get_global_transform_with_canvas().origin
	_bubble.reset_size()
	_bubble.position = screen + Vector2(-_bubble.size.x / 2.0, -34.0 - _bubble.size.y)


func _dialog_open() -> bool:
	var d := get_tree().get_first_node_in_group("dialog_box")
	return d != null and d.is_open()


func _find_npc(npc_id: String) -> Node2D:
	for n in get_tree().get_nodes_in_group("npcs"):
		if n.npc_id == npc_id and not n._leaving:
			return n
	return null


func _try_start() -> void:
	if _dialog_open():
		return
	var keys := _pairs.keys()
	keys.shuffle()
	for key in keys:
		var ids: PackedStringArray = str(key).split("+")
		if ids.size() != 2:
			continue
		var a := _find_npc(ids[0])
		var b := _find_npc(ids[1])
		if a == null or b == null:
			continue
		if a.is_being_called() or b.is_being_called() or a._returning or b._returning:
			continue
		if a.global_position.distance_to(b.global_position) > TRIGGER_DIST:
			continue
		var scripts: Array = _pairs[key]
		if scripts.is_empty():
			continue
		_play(a, b, scripts[randi() % scripts.size()])
		return


func _play(a: Node2D, b: Node2D, lines: Array) -> void:
	_busy = true
	a._bantering = true
	b._bantering = true
	a.face_toward(b.global_position)
	b.face_toward(a.global_position)
	var actors := {}
	for id in [a.npc_id, b.npc_id]:
		actors[id] = a if a.npc_id == id else b
	for line in lines:
		var speaker: Node2D = actors.get(str(line.get("who", "")), a)
		_bubble_label.text = str(line.get("text", ""))
		_bubble_target = speaker
		_bubble.show()
		_follow_target()
		await get_tree().create_timer(LINE_SECONDS).timeout
	_bubble.hide()
	_bubble_target = null
	# 说话期间可能有人下班离场，释放前确认节点还活着
	if is_instance_valid(a):
		a._bantering = false
	if is_instance_valid(b):
		b._bantering = false
	_busy = false
	_check_left = COOLDOWN
