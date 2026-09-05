extends Node
## 地图连通性 lint：
## 1) 日程表用到的房间都有对应场景（scenes/<room>.tscn）且 room_id 对得上
## 2) 每个房间场景里的门：目标场景存在、目标出生点在目标场景 Spawns/ 下
## 3) 日程坐标都在房间范围内（各房间 room_size）
## 用法：godot --headless --path <项目> res://tools/test_map.tscn
## 注意：本节点会把自己挪到场景树根下，免得换场景时被一起释放

const RoomScript := preload("res://scripts/room.gd")
const DoorScript := preload("res://scripts/door.gd")

var _failures := 0


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	var tree := get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	_run()


func _run() -> void:
	var rooms := {}
	for id in Schedule.all_npc_ids():
		for e in Schedule._data()[id]:
			var r := str(e.get("room", ""))
			if not r.is_empty():
				rooms[r] = true
			var scene: Node = load("res://scenes/%s.tscn" % r).instantiate()
			var bounds: Vector2 = scene.room_size
			scene.free()
			var pos: Array = e.get("pos", [])
			var in_bounds: bool = pos.size() == 2 and pos[0] >= 0 and pos[0] <= bounds.x and pos[1] >= 0 and pos[1] <= bounds.y
			_check(in_bounds, "%s 槽位 %s 坐标应在房间范围内" % [id, e.get("from", "?")])
	for room in rooms.keys():
		_check_room(room)
	print("MAP TEST: done")
	get_tree().quit(1 if _failures > 0 else 0)


func _check_room(room: String) -> void:
	var path := "res://scenes/%s.tscn" % room
	_check(ResourceLoader.exists(path), "日程房间应有场景: " + path)
	if not ResourceLoader.exists(path):
		return
	var inst: Node = load(path).instantiate()
	_check(inst.get_script() == RoomScript, "%s 应挂 room.gd" % path)
	if inst.get_script() == RoomScript:
		_check(inst.room_id == room, "%s 的 room_id 应为 \"%s\"（实际: \"%s\"）" % [path, room, inst.room_id])
	_check(inst.get_node_or_null("Spawns") != null, "%s 应有 Spawns 节点" % path)
	for child in inst.get_children():
		if child.get_script() == DoorScript:
			_check_door(room, child)
	inst.free()


func _check_door(from_room: String, door: Node) -> void:
	var target := str(door.target_room)
	var spawn := str(door.target_spawn)
	_check(not target.is_empty(), "%s 的门 %s 应有目标房间" % [from_room, door.name])
	if target.is_empty():
		return
	_check(ResourceLoader.exists(target), "%s 的门 %s 目标应存在: %s" % [from_room, door.name, target])
	if not ResourceLoader.exists(target):
		return
	var tgt: Node = load(target).instantiate()
	_check(tgt.get_node_or_null("Spawns/" + spawn) != null,
		"%s 的门 %s 目标出生点应存在: %s Spawns/%s" % [from_room, door.name, target, spawn])
	tgt.free()


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  PASS: " + msg)
	else:
		_failures += 1
		push_error("  FAIL: " + msg)
