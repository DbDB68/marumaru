extends CharacterBody2D
## 小狐狸主角：四方向移动 + 走路动画 + 按 Z 与附近刀男搭话
## 素材表 assets/sprites/player.png 行顺序：down / up / left / right，每方向 2 帧

const SPEED := 90.0
const INTERACT_RANGE := 48.0
const CALL_RANGE := 200.0
var _call_hint: Label
var _hint_left := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	var layer := CanvasLayer.new()
	add_child(layer)
	_call_hint = Label.new()
	_call_hint.position = Vector2(8, 34)
	_call_hint.add_theme_font_size_override("font_size", 12)
	_call_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	_call_hint.add_theme_constant_override("shadow_offset_x", 1)
	_call_hint.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_call_hint)
	show_call_hint("C 招呼附近的刀男过来")


func show_call_hint(text: String) -> void:
	_call_hint.text = text
	_hint_left = 3.0


func _process(delta: float) -> void:
	_hint_left -= delta
	_call_hint.visible = _hint_left > 0.0


func call_nearby() -> void:
	if _ui_busy():
		return
	var nearest: Node2D = null
	var distance := CALL_RANGE
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.is_being_called():
			show_call_hint("他已经在过来啦，稍等一下")
			return
		if npc._leaving or npc._bantering:
			continue
		var d := global_position.distance_to(npc.global_position)
		if d < distance:
			distance = d
			nearest = npc
	if nearest == null:
		show_call_hint("附近暂时没有空闲的刀男，靠近些再喊吧")
	elif nearest.answer_call(self):
		show_call_hint("听见啦，正在过来")
	else:
		show_call_hint("中间有东西挡着，走近一些再招呼吧")


func _physics_process(_delta: float) -> void:
	if _ui_busy():
		# 对话/面板开着时站住，动画也要立正
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	_update_animation(dir)


func _unhandled_input(event: InputEvent) -> void:
	# 忽略按住不放时的键盘连发，否则开关对话会疯狂切换
	if event is InputEventKey and event.is_echo():
		return
	if event.is_action_pressed("call_npc"):
		call_nearby()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not _ui_busy():
		var npc := _nearest_npc()
		if npc != null:
			npc.face_toward(global_position)
			_dialog().open(npc.get_lines())
			get_viewport().set_input_as_handled()


func _update_animation(dir: Vector2) -> void:
	if dir.is_zero_approx():
		sprite.pause()
		sprite.frame = 0
		return
	# 斜向移动时按主轴选朝向
	if absf(dir.x) > absf(dir.y):
		sprite.play(&"walk_right" if dir.x > 0.0 else &"walk_left")
	else:
		sprite.play(&"walk_down" if dir.y > 0.0 else &"walk_up")


func _nearest_npc() -> Node2D:
	var best: Node2D = null
	var best_dist := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group("npcs"):
		var d := global_position.distance_to(n.global_position)
		if d < best_dist:
			best = n
			best_dist = d
	return best


func _dialog() -> Node:
	return get_tree().get_first_node_in_group("dialog_box")


func _dialog_open() -> bool:
	var d := _dialog()
	return d != null and d.is_open()


## 任一界面（对话框/远征面板）开着都算忙
func _ui_busy() -> bool:
	if _dialog_open():
		return true
	var p := get_tree().get_first_node_in_group("expedition_panel")
	return p != null and p.is_open()
