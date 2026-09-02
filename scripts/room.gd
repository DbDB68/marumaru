extends Node2D
## 房间基座：
## 1) 切换进来时把主角摆到 Game 指定的出生点（出生点放在 Spawns/ 下）
## 2) 按日程表生成此刻应该在这个房间的刀男

@export var room_id := ""


func _ready() -> void:
	_place_player()
	_spawn_npcs()


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
