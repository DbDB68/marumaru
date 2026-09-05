extends SceneTree
## Exercise every courtyard doorway and physics-test the garden crossing.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for room in ["Main", "Kitchen", "Engawa", "Dojo", "Field"]:
		change_scene_to_file("res://scenes/courtyard.tscn")
		await create_timer(0.7).timeout
		var door = current_scene.get_node("DoorTo" + room)
		current_scene.get_node("Player").global_position = door.position
		await create_timer(0.9).timeout
		check(current_scene.room_id == room.to_lower(), "Enter " + room)
		var exit_door: Node2D
		for child in current_scene.get_children():
			if child.get_script() == load("res://scripts/door.gd") and child.target_room == "res://scenes/courtyard.tscn":
				exit_door = child
		check(exit_door != null, "Return door " + room)
		if exit_door == null:
			continue
		current_scene.get_node("Player").global_position = exit_door.position
		await create_timer(0.9).timeout
		check(current_scene.room_id == "courtyard", "Return " + room)
		var expected = current_scene.get_node("Spawns/From" + room).position
		check(current_scene.get_node("Player").position.distance_to(expected) < 1, "Safe spawn " + room)
	var player = current_scene.get_node("Player")
	player.set_physics_process(false)
	# Walk the eastern bridge from south to north, using the actual player shape.
	player.position = Vector2(1117, 705)
	for i in range(60):
		await physics_frame
		player.velocity = Vector2(0, -90)
		player.move_and_slide()
	check(player.position.y < 630, "Bridge must be walkable")
	# The same crossing away from the bridge must stop at the water.
	player.position = Vector2(1030, 700)
	for i in range(60):
		await physics_frame
		player.velocity = Vector2(0, -90)
		player.move_and_slide()
	check(player.position.y > 630, "Creek must block walking outside bridge")
	print("COURTYARD TEST: %d failures" % failures)
	quit(1 if failures else 0)
