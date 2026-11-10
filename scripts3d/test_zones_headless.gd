extends SceneTree

func _after_enter_tree():
	print("=== Headless Zone Test ===")

	# Test loading all zone scenes
	var zones = [
		"res://scenes3d/Room_camino_entrada.tscn",
		"res://scenes3d/Room_casa_principal.tscn",
		"res://scenes3d/Room_campo_cultivo.tscn",
		"res://scenes3d/Room_bosque.tscn",
		"res://scenes3d/Room_pozo.tscn",
		"res://scenes3d/Room_crater_meteorito.tscn",
		"res://scenes3d/Room_establo.tscn",
		"res://scenes3d/Room_atico.tscn",
		"res://scenes3d/Room_laberinto.tscn",
	]

	for zone_path in zones:
		var scene = load(zone_path)
		if scene:
			var instance = scene.instantiate()
			root.add_child(instance)
			await self.process_frame
			print("Loaded: ", zone_path)

			# Check for ExitArea3D nodes
			var exits = instance.find_children("*", "ExitArea3D", true, false)
			for exit in exits:
				print("  Exit: ", exit.name, " -> target_zone: ", exit.target_zone, " spawn_marker: ", exit.spawn_marker)

			# Check for Spawn markers
			var spawns = instance.find_children("Spawn*", "Marker3D", true, false)
			for spawn in spawns:
				print("  Spawn marker: ", spawn.name, " pos: ", spawn.global_position)

			instance.queue_free()
		else:
			print("FAILED to load: ", zone_path)

	print("=== All zones loaded successfully ===")
	quit(0)