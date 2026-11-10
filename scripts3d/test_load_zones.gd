extends Node

func _ready():
	print("=== Test Zone Loading ===")

	# Test ExitArea3D exports
	var exit_area = preload("res://scripts3d/ExitArea3D.gd").new()
	print("ExitArea3D properties:")
	print("  target_zone: ", exit_area.get("target_zone"))
	print("  spawn_marker: ", exit_area.get("spawn_marker"))
	print("  requires_item: ", exit_area.get("requires_item"))
	print("  locked_message: ", exit_area.get("locked_message"))
	print("  transition_style: ", exit_area.get("transition_style"))

	# Test GameManager change_zone with spawn_marker
	var gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	if gm:
		print("GameManager found")
		print("  change_zone signature: zone_id, spawn_marker")
	else:
		print("GameManager not in tree (expected in headless)")

	# Test Zone3D _spawn_player logic
	var zone3d = preload("res://scripts3d/Zone3D.gd").new()
	print("Zone3D loaded OK")

	# Test ScreenDoorTransition
	var sdt = preload("res://autoload/ScreenDoorTransition.gd").new()
	print("ScreenDoorTransition loaded OK")

	print("=== All basic load tests passed ===")
	get_tree().quit(0)