extends CanvasLayer
## 底部对话框：打字机逐字显示，Z / 回车翻页或关闭
## 用法：open(["第一句", "第二句"])；外部用 is_open() 查询状态

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/MarginContainer/Label
@onready var timer: Timer = $Timer

var _lines: Array[String] = []
var _index := 0
var _open := false
var _typing := false


func _ready() -> void:
	add_to_group("dialog_box")
	panel.hide()
	timer.timeout.connect(_on_tick)


func open(lines: Array) -> void:
	_lines.assign(lines)
	_index = 0
	_open = true
	panel.show()
	_show_line()


func is_open() -> bool:
	return _open


func _show_line() -> void:
	label.text = _lines[_index]
	label.visible_characters = 0
	_typing = true
	timer.start(0.04)


func _on_tick() -> void:
	if label.visible_characters < label.get_total_character_count():
		label.visible_characters += 1
	else:
		_finish_typing()


func _finish_typing() -> void:
	label.visible_characters = -1  # -1 = 全部显示
	_typing = false
	timer.stop()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	# 忽略按住不放时的键盘连发
	if event is InputEventKey and event.is_echo():
		return
	# Esc 随时强制关闭
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _typing:
			# 还在打字 → 直接显示全
			_finish_typing()
		else:
			_index += 1
			if _index >= _lines.size():
				_close()
			else:
				_show_line()
		get_viewport().set_input_as_handled()


func _close() -> void:
	_open = false
	panel.hide()
	timer.stop()
