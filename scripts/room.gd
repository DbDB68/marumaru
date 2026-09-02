extends Node2D
## 房间基座：切换进来时把主角摆到 Game 指定的出生点
## 出生点放在 Spawns/ 下，名字与门的 target_spawn 对应

func _ready() -> void:
	var spawn_name := Game.take_spawn()
	if spawn_name.is_empty():
		return
	var marker := get_node_or_null("Spawns/" + spawn_name)
	var player := get_node_or_null("Player")
	if marker != null and player != null:
		player.global_position = marker.global_position
