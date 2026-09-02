extends Area2D
## 门：玩家踏入就切换到目标房间的指定出生点

@export_file("*.tscn") var target_room := ""
@export var target_spawn := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not target_room.is_empty():
		Game.change_room(target_room, target_spawn)
