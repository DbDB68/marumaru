extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	change_scene_to_file("res://scenes/courtyard.tscn")
	await create_timer(0.3).timeout
	for old in get_nodes_in_group("npcs"):
		old.queue_free()
	await process_frame
	var player = current_scene.get_node("Player")
	player.position = Vector2(700, 950)
	var npc = load("res://scenes/npcs/hasebe.tscn").instantiate()
	current_scene.add_child(npc)
	npc._apply_slot({"pos": [800, 950], "mode": "stay", "from": "test"}, true)
	npc._schedule_check_left = 1000
	await physics_frame
	var event := InputEventAction.new()
	event.action = "call_npc"
	event.pressed = true
	player._unhandled_input(event)
	check(npc.is_being_called(), "C action should call nearby NPC")
	player.call_nearby()
	check(npc.is_being_called(), "Repeated call must not cancel approach")
	await create_timer(2.0).timeout
	var dialog = get_first_node_in_group("dialog_box")
	check(dialog.is_open(), "Arrival should greet player")
	check(npc.position.distance_to(player.position) <= 35, "NPC should physically approach")
	dialog._close()
	await create_timer(2.0).timeout
	check(npc.position.distance_to(Vector2(800,950)) < 5, "Stay NPC returns to schedule position")
	# A body-width sweep rejects a call across the solid main building.
	player.position = Vector2(515, 300)
	npc.position = Vector2(715, 300)
	await physics_frame
	check(not npc.answer_call(player), "Do not walk through a building")
	npc._bantering = true
	check(not npc.answer_call(player), "Do not interrupt banter")
	npc._bantering = false
	npc._leave_room()
	check(not npc.answer_call(player), "Do not call a leaving NPC")
	print("CALL TEST: %d failures" % failures)
	quit(1 if failures else 0)
