extends CharacterBody2D
## 刀男 NPC：待机 + 随机溜达；玩家靠近可按 Z 搭话
## 素材表与主角同规格：行顺序 down / up / left / right，每方向 2 帧

const SPEED := 45.0
const ROAM_RADIUS := 110.0
const IDLE_MIN := 1.5
const IDLE_MAX := 4.5

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


func _ready() -> void:
	add_to_group("npcs")
	_home = global_position
	_idle_left = randf_range(IDLE_MIN, IDLE_MAX)


func _physics_process(delta: float) -> void:
	if _dialog_open():
		# 对话时立正
		velocity = Vector2.ZERO
		sprite.pause()
		return
	if _walking:
		_walk_step(delta)
	else:
		velocity = Vector2.ZERO
		_idle_left -= delta
		if _idle_left <= 0.0:
			_pick_target()


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
