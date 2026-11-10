extends Node
class_name TestPlayerOrientation

signal test_completed(passed: bool, results: Dictionary)

var _player: Player3D = null
var _camera: Camera3D = null
var _results: Dictionary = {}
var _test_timer: float = 0.0
var _phase: int = 0
var _initial_pos: Vector3 = Vector3.ZERO
var _initial_rot: float = 0.0

func _ready() -> void:
	print("=== TestPlayerOrientation: Iniciando verificación ===")
	_results = {
		"w_moves_forward": false,
		"camera_behind": false,
		"a_turns_left": false,
		"d_turns_right": false,
		"height_ok": false,
		"feet_on_ground": false,
		"details": {}
	}

	# Instanciar Player3D
	var player_scene = load("res://scenes3d/Player3D.tscn")
	if player_scene == null:
		print("ERROR: No se pudo cargar res://scenes3d/Player3D.tscn")
		_finish_test(false)
		return

	_player = player_scene.instantiate()
	add_child(_player)
	_player.global_position = Vector3(0, 0.1, 0)  # Spawn offset como en Zone3D

	# Esperar un frame para que _ready() del player ejecute
	call_deferred("_start_tests")

func _start_tests() -> void:
	if not is_instance_valid(_player):
		print("ERROR: Player no válido")
		_finish_test(false)
		return

	_camera = _player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if not is_instance_valid(_camera):
		print("ERROR: Cámara no encontrada")
		_finish_test(false)
		return

	_initial_pos = _player.global_position
	_initial_rot = _player.rotation.y

	print("Player instanciado en:", _initial_pos)
	print("Rotación inicial (y):", _initial_rot)
	print("Camera global_position:", _camera.global_position)
	print("Camera global_rotation:", _camera.global_rotation)

	# Medir altura del modelo
	var mesh_root = _player.get_node_or_null("MeshRoot")
	if mesh_root:
		var aabb = mesh_root.get_aabb()
		var height = aabb.size.y
		print("Modelo AABB height:", height)
		_results.details.model_aabb_height = height
		_results.details.model_aabb_min_y = aabb.position.y
		_results.details.model_aabb_max_y = aabb.position.y + aabb.size.y

	# Medir cápsula
	var capsule_shape = _player.get_node_or_null("CollisionShape3D").shape
	if capsule_shape:
		print("Cápsula height:", capsule_shape.height, "radius:", capsule_shape.radius)
		_results.details.capsule_height = capsule_shape.height
		_results.details.capsule_radius = capsule_shape.radius

	# Test 1: Verificar cámara detrás (dot product)
	_test_camera_behind()

	# Test 2: Verificar altura y pies en suelo
	_test_height_and_ground()

	# Test 3-6: Tests de movimiento (requieren simular input)
	# Usamos _physics_process para simular
	set_physics_process(true)

func _test_camera_behind() -> void:
	# Vector forward del personaje (hacia donde mira)
	var char_forward = Vector3(sin(_player.facing_angle), 0, cos(_player.facing_angle)).normalized()

	# Vector de personaje a cámara
	var to_camera = (_camera.global_position - _player.global_position).normalized()
	to_camera.y = 0  # Solo plano horizontal
	to_camera = to_camera.normalized()

	var dot = char_forward.dot(to_camera)
	print("Test cámara detrás: char_forward=", char_forward, " to_camera=", to_camera, " dot=", dot)

	_results.details.camera_dot = dot
	_results.details.char_forward = [char_forward.x, char_forward.y, char_forward.z]
	_results.details.to_camera = [to_camera.x, to_camera.y, to_camera.z]

	# Cámara detrás = dot > 0.9 (cámara en -Z relativo al personaje = opuesto al forward)
	# Si personaje mira +Z, cámara debe estar en -Z => dot ≈ -1
	# Pero wait: cámara atrás significa que el personaje da la espalda a la cámara
	# Si personaje mira +Z (forward), cámara está en -Z (atrás)
	# Vector personaje->cámara = (0, 0, -1) approx
	# Forward personaje = (0, 0, 1)
	# Dot = -1

	# El requisito dice "cámara detrás (dot > 0.9)" - esto parece referirse a
	# que la cámara mira en la misma dirección que el personaje (mira su espalda)
	# camera.global_transform.basis.z (direction camera mira) vs character forward

	var cam_forward = -_camera.global_transform.basis.z  # Cámara mira hacia -Z local
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()

	var dot2 = char_forward.dot(cam_forward)
	print("  Camera forward (world):", cam_forward, " dot con char_forward:", dot2)
	_results.details.camera_forward_dot = dot2

	# La cámara mira hacia el personaje (su espalda), así que camera_forward apunta hacia el personaje
	# char_forward apunta hacia adelante del personaje
	# Si cámara está detrás mirando al personaje: camera_forward ≈ -char_forward => dot ≈ -1
	# Pero el test pide "dot > 0.9" - puede significar que la cámara mira en la misma dirección
	# que el personaje (ambos miran hacia +Z)

	# En nuestra config: CameraPivot.global_rotation.y = camera_yaw ≈ facing_angle
	# SpringArm pone cámara en -Z local del CameraPivot
	# Así que cámara mira hacia +Z (igual que personaje)
	var cam_look_dir = -_camera.global_transform.basis.z
	cam_look_dir.y = 0
	cam_look_dir = cam_look_dir.normalized()

	var dot3 = char_forward.dot(cam_look_dir)
	print("  Camera look dir:", cam_look_dir, " dot:", dot3)
	_results.details.camera_look_dot = dot3

	# Con SpringArm: cámara en posición -Z del pivot, mirando hacia +Z
	# Si pivot mira igual que personaje (camera_yaw = facing_angle), entonces
	# cámara mira en misma dirección que personaje
	# dot3 debería ser ≈ 1.0
	_results["camera_behind"] = dot3 > 0.9

func _test_height_and_ground() -> void:
	var mesh_root = _player.get_node_or_null("MeshRoot")
	if mesh_root:
		var aabb = mesh_root.get_aabb()
		var world_aabb = mesh_root.global_transform * aabb
		var min_y = world_aabb.position.y
		var max_y = world_aabb.position.y + world_aabb.size.y
		var height = max_y - min_y

		print("Test altura: min_y=", min_y, " max_y=", max_y, " height=", height)

		_results.details.world_min_y = min_y
		_results.details.world_max_y = max_y
		_results.details.world_height = height

		# Altura objetivo ≈ 1.8m
		_results["height_ok"] = abs(height - 1.8) < 0.1

		# Pies en suelo: min_y ≈ 0 (con tolerancia pequeña)
		_results["feet_on_ground"] = abs(min_y) < 0.05

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	_test_timer += delta

	match _phase:
		0:  # Test W (avanzar)
			if _test_timer < 0.1:
				Input.action_press("move_forward")
			elif _test_timer < 1.0:
				# Dejar mover
				pass
			else:
				Input.action_release("move_forward")
				var moved = _player.global_position.z - _initial_pos.z
				print("Test W: moved z =", moved, " (esperado > 0)")
				_results.details.w_moved_z = moved
				_results["w_moves_forward"] = moved > 0.1
				_phase = 1
				_test_timer = 0.0
				_initial_pos = _player.global_position
				_initial_rot = _player.rotation.y

		1:  # Test S (retroceder)
			if _test_timer < 0.1:
				Input.action_press("move_backward")
			elif _test_timer < 1.0:
				pass
			else:
				Input.action_release("move_backward")
				var moved = _player.global_position.z - _initial_pos.z
				print("Test S: moved z =", moved, " (esperado < 0)")
				_results.details.s_moved_z = moved
				_phase = 2
				_test_timer = 0.0
				_initial_rot = _player.rotation.y

		2:  # Test A (girar izquierda)
			if _test_timer < 0.1:
				Input.action_press("turn_left")
			elif _test_timer < 1.0:
				pass
			else:
				Input.action_release("turn_left")
				var rot_diff = _player.rotation.y - _initial_rot
				# Normalizar a [-PI, PI]
				rot_diff = fmod(rot_diff + PI, 2 * PI) - PI
				print("Test A: rot_diff =", rot_diff, " (esperado > 0, girar izq = +Y)")
				_results.details.a_rot_diff = rot_diff
				_results["a_turns_left"] = rot_diff > 0.1
				_phase = 3
				_test_timer = 0.0
				_initial_rot = _player.rotation.y

		3:  # Test D (girar derecha)
			if _test_timer < 0.1:
				Input.action_press("turn_right")
			elif _test_timer < 1.0:
				pass
			else:
				Input.action_release("turn_right")
				var rot_diff = _player.rotation.y - _initial_rot
				rot_diff = fmod(rot_diff + PI, 2 * PI) - PI
				print("Test D: rot_diff =", rot_diff, " (esperado < 0, girar der = -Y)")
				_results.details.d_rot_diff = rot_diff
				_results["d_turns_right"] = rot_diff < -0.1
				_phase = 4
				_test_timer = 0.0

		4:
			set_physics_process(false)
			call_deferred("_finish_test", true)

func _finish_test(passed: bool) -> void:
	var all_passed = true
	for key in ["w_moves_forward", "camera_behind", "a_turns_left", "d_turns_right", "height_ok", "feet_on_ground"]:
		if not _results.get(key, false):
			all_passed = false
			break

	_results["all_passed"] = all_passed

	print("=== RESULTADOS ===")
	for key in ["w_moves_forward", "camera_behind", "a_turns_left", "d_turns_right", "height_ok", "feet_on_ground"]:
		var status = "PASS" if _results.get(key, false) else "FAIL"
		print("  ", key, ":", status)

	print("  ALL:", "PASS" if all_passed else "FAIL")
	print("Details:", _results)

	test_completed.emit(all_passed, _results)

	# Salir
	get_tree().quit()