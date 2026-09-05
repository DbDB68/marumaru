extends CharacterBody2D
## 刀男 NPC：按日程表（data/schedules.json）生活
## - mode=wander：据点附近待机 + 随机溜达；mode=stay：原地站桩
## - 到点换活动：同房间走过去，换房间就下班消失（去别的房间能逮到他）
## 素材表与主角同规格：行顺序 down / up / left / right，每方向 2 帧

const SPEED := 45.0
const ROAM_RADIUS := 110.0
const IDLE_MIN := 1.5
const IDLE_MAX := 4.5
const SCHEDULE_CHECK_INTERVAL := 10.0

@export var npc_id := "hasebe"
@export var lines: Array[String] = [
	"主。……有何吩咐？",
	"本丸的警备就交给我吧。",
	"压切长谷部，随侍在侧。",
	"需要我做什么？无论是泡茶还是……斩人。",
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _home: Vector2
var _target: Vector2
var _idle_left := 0.0
var _walking := false
var _stuck := 0.0
var _slot: Dictionary = {}
var _mode := "wander"
var _schedule_check_left := SCHEDULE_CHECK_INTERVAL
var _leaving := false
var _bantering := false  # 小剧场（banter.gd）搭话中：立正站好
var _call_player: Node2D
var _call_left := 0.0
var _returning := false


func is_being_called() -> bool:
	return is_instance_valid(_call_player)


func answer_call(player: Node2D) -> bool:
	if _leaving or _bantering or is_being_called():
		return false
	# Sweep the real body shape: do not promise a route through water or walls.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = $CollisionShape2D.global_transform
	query.motion = player.global_position - global_position
	query.exclude = [get_rid(), player.get_rid()]
	var travel := get_world_2d().direct_space_state.cast_motion(query)
	if travel[0] < 0.99:
		return false
	_call_player = player
	_call_left = 8.0
	_returning = false
	_stuck = 0.0
	return true


func _finish_call() -> void:
	_call_player = null
	_target = _home
	_returning = true
	_walking = true
	_stuck = 0.0


func _approach_player(delta: float) -> void:
	_call_left -= delta
	var distance := global_position.distance_to(_call_player.global_position)
	if distance <= 34.0:
		face_toward(_call_player.global_position)
		var dialog := get_tree().get_first_node_in_group("dialog_box")
		if dialog != null:
			dialog.open(["长谷部：主，有何吩咐？" if npc_id == "hasebe" else "不动：嗯……主叫我？"])
		_finish_call()
		velocity = Vector2.ZERO
		return
	if _call_left <= 0.0 or distance > 240.0:
		_call_player.show_call_hint("没能走到你身边，靠近一些再喊吧")
		_finish_call()
		return
	_target = _call_player.global_position
	_walk_step(delta)


func _ready() -> void:
	add_to_group("npcs")
	_apply_slot(Schedule.current_slot(npc_id), true)
	_idle_left = randf_range(IDLE_MIN, IDLE_MAX)


func _physics_process(delta: float) -> void:
	if _leaving:
		return
	var panel := get_tree().get_first_node_in_group("expedition_panel")
	if _bantering or _dialog_open() or (panel != null and panel.is_open()):
		# 搭话/小剧场时立正
		velocity = Vector2.ZERO
		sprite.pause()
		return
	_schedule_check_left -= delta
	if _schedule_check_left <= 0.0:
		_schedule_check_left = SCHEDULE_CHECK_INTERVAL
		_check_schedule()
	if _leaving:
		return
	if is_being_called():
		_approach_player(delta)
		return
	if _returning:
		_walk_step(delta)
		if not _walking:
			_returning = false
		return
	if _mode == "stay":
		velocity = Vector2.ZERO
		return
	if _walking:
		_walk_step(delta)
	else:
		velocity = Vector2.ZERO
		_idle_left -= delta
		if _idle_left <= 0.0:
			_pick_target()


## 应用日程槽；teleport 为 true 时直接摆到位（出生用），否则走过去
func _apply_slot(slot: Dictionary, teleport := false) -> void:
	_call_player = null
	_returning = false
	_slot = slot
	if slot.is_empty():
		_home = global_position
		return
	var pos: Array = slot.get("pos", [global_position.x, global_position.y])
	_home = Vector2(pos[0], pos[1])
	_mode = slot.get("mode", "wander")
	if slot.has("lines"):
		lines.assign(slot["lines"])
	if teleport:
		global_position = _home
	else:
		# 同房间换活动：走向新据点
		_target = _home
		_walking = true
		_stuck = 0.0


func _check_schedule() -> void:
	var slot := Schedule.current_slot(npc_id)
	if slot.is_empty() or slot.get("from") == _slot.get("from"):
		return
	if slot.get("room") != _slot.get("room"):
		_leave_room()
	else:
		_apply_slot(slot)


## 换房间：淡出消失（目标房间加载时房间脚本会按日程重新生成他）
func _leave_room() -> void:
	_call_player = null
	_leaving = true
	velocity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)


func _walk_step(delta: float) -> void:
	var to := _target - global_position
	if to.length() < 4.0:
		_stop()
		return
	velocity = to.normalized() * SPEED
	var before := global_position
	move_and_slide()
	_play_walk(to)
	# 被家具卡住就换个地儿
	if global_position.distance_to(before) < SPEED * delta * 0.3:
		_stuck += delta
		if _stuck > 0.4:
			_stop()
	else:
		_stuck = 0.0


func _pick_target() -> void:
	var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30.0, ROAM_RADIUS)
	_target = _home + offset
	_walking = true
	_stuck = 0.0


func _stop() -> void:
	_walking = false
	_idle_left = randf_range(IDLE_MIN, IDLE_MAX)
	velocity = Vector2.ZERO
	sprite.pause()
	sprite.frame = 0


func _play_walk(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		sprite.play(&"walk_right" if dir.x > 0.0 else &"walk_left")
	else:
		sprite.play(&"walk_down" if dir.y > 0.0 else &"walk_up")


## 被搭话时面朝玩家立正
func face_toward(p: Vector2) -> void:
	var dir := p - global_position
	if absf(dir.x) > absf(dir.y):
		sprite.animation = &"walk_right" if dir.x > 0.0 else &"walk_left"
	else:
		sprite.animation = &"walk_down" if dir.y > 0.0 else &"walk_up"
	sprite.pause()
	sprite.frame = 0


func get_lines() -> Array[String]:
	return [lines.pick_random()]


func _dialog_open() -> bool:
	var d := get_tree().get_first_node_in_group("dialog_box")
	return d != null and d.is_open()
