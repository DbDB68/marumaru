extends Node
## 全局场景切换器（Autoload: Game）
## 房间之间切换：黑屏淡出 → 换场景 → 淡入，并把主角放到指定出生点

var _pending_spawn := ""
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func change_room(room_path: String, spawn_name: String) -> void:
	if _busy:
		return
	_busy = true
	_pending_spawn = spawn_name
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, 0.25)
	await out.finished
	get_tree().change_scene_to_file(room_path)
	# 等新房间 _ready 跑完（出生点摆放发生在那里）
	await get_tree().process_frame
	await get_tree().process_frame
	var in_ := create_tween()
	in_.tween_property(_fade, "modulate:a", 0.0, 0.25)
	await in_.finished
	_busy = false


## 房间 _ready 时调用，取走本次切换指定的出生点名（仅一次有效）
func take_spawn() -> String:
	var s := _pending_spawn
	_pending_spawn = ""
	return s
