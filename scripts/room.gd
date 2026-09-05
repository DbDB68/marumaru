extends Node2D
## 房间基座：
## 1) 切换进来时把主角摆到 Game 指定的出生点（出生点放在 Spawns/ 下）
## 2) 按日程表生成此刻应该在这个房间的刀男（远征中的刀男不出现）
## 3) 监听远征出发/归来，刀男实时离场/回场

@export var room_id := ""
@export var room_size := Vector2(960, 540)

const Banter := preload("res://scripts/banter.gd")


func _ready() -> void:
	_place_player()
	var camera := get_node_or_null("Player/Camera2D") as Camera2D
	if camera != null:
		camera.limit_right = int(room_size.x)
		camera.limit_bottom = int(room_size.y)
		if room_id == "courtyard":
			camera.zoom = Vector2(1.5, 1.5)
		camera.reset_smoothing()
	_spawn_npcs()
	add_child(Banter.new())
	Expedition.started.connect(_on_expedition_started)
	Expedition.finished.connect(_on_expedition_finished)


func _place_player() -> void:
	var spawn_name := Game.take_spawn()
	if spawn_name.is_empty():
		return
	var marker := get_node_or_null("Spawns/" + spawn_name)
	var player := get_node_or_null("Player")
	if marker != null and player != null:
		player.global_position = marker.global_position


func _spawn_npcs() -> void:
	for npc_id in Schedule.all_npc_ids():
		if Expedition.is_away(npc_id):
			continue
		if _has_npc(npc_id):
			continue
		var slot := Schedule.current_slot(npc_id)
		if slot.get("room", "") != room_id:
			continue
		var scene_path := "res://scenes/npcs/%s.tscn" % npc_id
		if not ResourceLoader.exists(scene_path):
			push_warning("刀男场景缺失: " + scene_path)
			continue
		var npc: Node2D = load(scene_path).instantiate()
		npc.npc_id = npc_id
		add_child(npc)


func _has_npc(npc_id: String) -> bool:
	for n in get_tree().get_nodes_in_group("npcs"):
		if n.npc_id == npc_id and not n._leaving:
			return true
	return false


## 远征出发：本房间里的刀男淡出离场
func _on_expedition_started() -> void:
	for n in get_tree().get_nodes_in_group("npcs"):
		n._leave_room()


## 远征归来：按当前日程把该在的刀男生成回来
func _on_expedition_finished() -> void:
	_spawn_npcs()
