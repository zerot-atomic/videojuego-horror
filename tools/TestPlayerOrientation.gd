extends Node
class_name TestPlayerOrientation

@export var run_duration: float = 10.0

var player: Player3D
var camera: Camera3D
var test_phase: int = 0
var phase_timer: float = 0.0
var results: Dictionary = {}
var start_pos: Vector3
var initial_facing: float

func _ready() -> void:
	print("=== TestPlayerOrientation START ===")

	# Instanciar Player3D
	var player_scene = load("res://scenes3d/Player3D.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 0.1, 0)  # spawn offset

	# Referencias
	camera = player.get_node("CameraPivot/SpringArm3D/Camera3D")

	# Esperar un frame para que _ready del player se ejecute
	await get_tree().process_frame
	await get_tree().process_frame

	start_pos = player.global_position
	initial_facing = player.facing_angle

	print("Player spawn pos: ", start_pos)
	print("Player initial facing: ", initial_facing)
	print("Camera global pos: ", camera.global_position)
	print("Camera global rot: ", camera.global_rotation)

	# Fase 1: W = adelante (+Z), cámara detrás
	test_phase = 1
	phase_timer = 0.0
	Input.action_press("move_forward")

	# Timer para avanzar fases
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.1
	timer.timeout.connect(_tick.bind())
	add_child(timer)
	timer.start()

func _tick() -> void:
	phase_timer += 0.1

	match test_phase:
		1: _check_phase_forward()
		2: _check_phase_camera_behind()
		3: _check_phase_turn_left()
		4: _check_phase_turn_right()
		5: _check_phase_height_feet()
		6: _check_phase_run()

	if test_phase <= 6:
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.1
		timer.timeout.connect(_tick.bind())
		add_child(timer)
		timer.start()
	else:
		_print_results()
		get_tree().quit()

func _check_phase_forward() -> void:
	if phase_timer >= 2.0:
		Input.action_release("move_forward")
		var delta_z = player.global_position.z - start_pos.z
		var forward_vec = Vector3(sin(player.facing_angle), 0, cos(player.facing_angle))
		var cam_to_player = (player.global_position - camera.global_position).normalized()
		var dot = forward_vec.dot(cam_to_player)

		results.forward_moved = delta_z > 0.5
		results.camera_behind = dot > 0.9

		print("Phase 1 (W forward): delta_z=", delta_z, " forward_moved=", results.forward_moved, " camera_behind=", results.camera_behind, " dot=", dot)

		test_phase = 2
		phase_timer = 0.0
		start_pos = player.global_position

func _check_phase_camera_behind() -> void:
	if phase_timer >= 0.5:
		var forward_vec = Vector3(sin(player.facing_angle), 0, cos(player.facing_angle))
		var cam_forward = -camera.global_transform.basis.z
		var dot = forward_vec.dot(cam_forward)

		results.camera_consistently_behind = dot > 0.9
		print("Phase 2 (camera behind): dot=", dot, " ok=", results.camera_consistently_behind)

		test_phase = 3
		phase_timer = 0.0
		initial_facing = player.facing_angle
		Input.action_press("turn_left")

func _check_phase_turn_left() -> void:
	if phase_timer >= 1.0:
		Input.action_release("turn_left")
		var angle_diff = player.facing_angle - initial_facing
		results.turn_left_works = angle_diff < -0.5  # giró izquierda (negativo)
		print("Phase 3 (A left): angle_diff=", angle_diff, " ok=", results.turn_left_works)

		test_phase = 4
		phase_timer = 0.0
		initial_facing = player.facing_angle
		Input.action_press("turn_right")

func _check_phase_turn_right() -> void:
	if phase_timer >= 1.0:
		Input.action_release("turn_right")
		var angle_diff = player.facing_angle - initial_facing
		results.turn_right_works = angle_diff > 0.5  # giró derecha (positivo)
		print("Phase 4 (D right): angle_diff=", angle_diff, " ok=", results.turn_right_works)

		test_phase = 5
		phase_timer = 0.0

func _check_phase_height_feet() -> void:
	if phase_timer >= 0.5:
		# Raycast down desde mesh para verificar pies en suelo
		var mesh_root = player.get_node("MeshRoot")
		var model_pivot = mesh_root.get_node("ModelPivot")
		var mesh_instance = model_pivot.get_node("inspector")

		var aabb = mesh_instance.get_aabb()
		var mesh_height = aabb.size.y * model_pivot.scale.y
		var model_bottom = model_pivot.global_position.y + aabb.position.y * model_pivot.scale.y

		results.mesh_height_ok = abs(mesh_height - 1.8) < 0.1
		results.feet_on_floor = abs(model_bottom) < 0.05

		print("Phase 5 (height/feet): mesh_height=", mesh_height, " model_bottom=", model_bottom)
		print("  height_ok=", results.mesh_height_ok, " feet_on_floor=", results.feet_on_floor)

		test_phase = 6
		phase_timer = 0.0
		start_pos = player.global_position
		Input.action_press("move_forward")
		Input.action_press("run")

func _check_phase_run() -> void:
	if phase_timer >= 1.5:
		Input.action_release("move_forward")
		Input.action_release("run")
		var delta_z = player.global_position.z - start_pos.z
		results.run_works = delta_z > 3.0  # correr más rápido
		print("Phase 6 (run): delta_z=", delta_z, " run_works=", results.run_works)

		test_phase = 7

func _print_results() -> void:
	print("=== TestPlayerOrientation RESULTS ===")
	var all_pass = true
	for key in results:
		var status = "PASS" if results[key] else "FAIL"
		if not results[key]:
			all_pass = false
		print(key, ": ", status)
	print("OVERALL: ", "PASS" if all_pass else "FAIL")
	print("=== TestPlayerOrientation END ===")