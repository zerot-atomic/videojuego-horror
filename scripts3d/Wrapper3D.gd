extends CharacterBody3D
class_name Wrapper3D
# ============================================================
# "The Wrapper" — el monstruo que acecha y persigue.
#
# QUE HACE (todo solo, sin pasarle nada mas que el jugador):
#   PATRULLA  camina entre puntos (patrol_points) y se detiene a mirar.
#   DETECTA   te ve (cono de vision + linea de vista, no atraviesa muros) o te
#             oye (segun el ruido que haces: Player3D.get_noise_radius()).
#               - Agachado (tecla C) te ve de mucho menos lejos y casi no te oye.
#               - Dentro de pastizal alto te ve de la mitad de lejos.
#   PERSIGUE  grita (una vez) y corre hacia ti, esquivando obstaculos.
#             Corriendo (Shift) le sacas ventaja: chase_speed < run_speed.
#   BUSCA     si te pierde unos segundos, va a donde te vio por ultima vez,
#             mira alrededor y vuelve a patrullar.
#   ATACA     si te alcanza: golpe de cordura (placeholder, ver _start_attack).
#   EMBOSCADA start_chase(jugador, true, true) = grita y NUNCA te pierde
#             (para la escena del granero).
#
# API publica:
#   start_patrol(puntos, jugador)
#   start_chase(jugador, con_grito = true, forzada = false)
#   stop_chase()
# ============================================================

signal player_caught(target)
signal stumbled()
signal spotted_player()
signal scream_started()

# Parámetros desde GameManager.GAMEPLAY (única fuente de verdad)
var patrol_speed: float
var search_speed: float
var chase_speed: float
var turn_speed: float
var attack_range: float
var attack_cooldown: float
var attack_sanity_damage: float
var sight_range: float
var sight_fov_deg: float
var crouch_sight_factor: float
var grass_sight_factor: float
var lose_time: float
var lose_range: float
var scream_cooldown: float
var stumble_chance: float
var stumble_duration: float
var stumble_cooldown_time: float
var gravity: float
@export var scream_sound: AudioStream        # (opcional) el grito; si lo dejas vacio no suena nada

enum State { INACTIVE, EMERGING, PATROL, SEARCHING, CHASING, STUMBLING, ATTACKING }

var state: State = State.INACTIVE
var target: Node3D = null
var patrol_points: Array = []                # Vector3 en coordenadas globales
var facing_angle: float = 0.0
var vertical_velocity: float = 0.0

var _forced: bool = false
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _stumble_cooldown: float = 0.0
var _scream_timer: float = 0.0
var _lost_timer: float = 0.0
var _last_known: Vector3 = Vector3.ZERO
var _wp_index: int = 0
var _pausing: bool = false
var _search_looking: bool = false
var _steer_sign: float = 1.0
var _anim_cache: Dictionary = {}
var _scream_player: AudioStreamPlayer3D = null
var _maze_nav_timer: float = 0.0
var _maze_goal: Vector3 = Vector3.INF
var _maze_waypoint: Vector3 = Vector3.ZERO
var _maze_path: Array[Vector2i] = []
var _maze_path_index: int = 1
var _target_get_run_speed = null
var _base_player_run_speed: float = 0.0
var _astar_grid: AStarGrid2D = null

@onready var mesh_root = $MeshRoot
@onready var anim_player = _find_anim_player()

func _ready() -> void:
	# Cargar parámetros centralizados
	var gp := GameManager.GAMEPLAY.enemy_wrapper
	patrol_speed = gp.patrol_speed
	search_speed = gp.search_speed
	chase_speed = gp.chase_speed
	turn_speed = gp.turn_speed
	attack_range = gp.attack_range
	attack_cooldown = gp.attack_cooldown
	attack_sanity_damage = gp.attack_sanity_damage
	sight_range = gp.sight_range
	sight_fov_deg = gp.sight_fov_deg
	crouch_sight_factor = gp.crouch_sight_factor
	grass_sight_factor = gp.grass_sight_factor
	lose_time = gp.lose_time
	lose_range = gp.lose_range
	scream_cooldown = gp.scream_cooldown
	stumble_chance = gp.stumble_chance
	stumble_duration = gp.stumble_duration
	stumble_cooldown_time = gp.stumble_cooldown_time
	gravity = gp.gravity
	# Cache base player run speed for rubber-band logic (BUG-007)
	_base_player_run_speed = float(GameManager.GAMEPLAY.player.run_speed)

	add_to_group("gripper")
	facing_angle = rotation.y
	_configure_loops()
	# Initialize AStarGrid2D once for maze navigation (BUG-003)
	var maze_room = get_parent().get_node_or_null("Room_laberinto")
	if maze_room != null and maze_room.has_method("get_maze_navigation"):
		var nav: Dictionary = maze_room.get_maze_navigation()
		var cell_size: float = nav.cell_size
		var cols: int = nav.cols
		var rows: int = nav.rows
		_astar_grid = AStarGrid2D.new()
		_astar_grid.region = Rect2i(Vector2i(0, 0), Vector2i(cols, rows))
		_astar_grid.cell_size = Vector2(cell_size, cell_size)
		_astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		# Mark solid cells from maze adjacency
		var adjacency: Dictionary = nav.adjacency
		for cell in adjacency:
			if not adjacency[cell].is_empty():
				_astar_grid.set_point_solid(cell, false)
			else:
				_astar_grid.set_point_solid(cell, true)
		_astar_grid.update()
	if scream_sound != null:
		_scream_player = AudioStreamPlayer3D.new()
		_scream_player.stream = scream_sound
		_scream_player.unit_size = 12.0
		_scream_player.max_distance = 80.0
		add_child(_scream_player)
	_play("Idle_Watchful")

# ------------------------------------------------------------------ API publica
func start_patrol(points: Array, new_target: Node3D) -> void:
	patrol_points = points
	target = new_target
	_wp_index = 0
	_enter_patrol()

func start_chase(new_target: Node3D, emerge_first: bool = true, forced: bool = false) -> void:
	target = new_target
	_forced = forced
	_lost_timer = 0.0
	if is_instance_valid(target):
		_last_known = target.global_position
		# Cache callable for get_effective_run_speed to avoid reflection overhead
		if target.has_method("get_effective_run_speed"):
			_target_get_run_speed = target.get_effective_run_speed.bind()
		else:
			_target_get_run_speed = null
	if emerge_first:
		_begin_scream()
	else:
		state = State.CHASING
		_play("Run_Frantic")

func stop_chase() -> void:
	state = State.INACTIVE
	target = null
	_forced = false
	_play("Idle_Watchful")

func get_state_name() -> String:
	return State.keys()[state]

# ------------------------------------------------------------------ bucle principal
func _physics_process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _stumble_cooldown > 0.0:
		_stumble_cooldown -= delta
	if _scream_timer > 0.0:
		_scream_timer -= delta

	match state:
		State.INACTIVE:
			return
		State.EMERGING:
			_state_timer -= delta
			_hold_in_place(delta)
			_face_target(delta)
			if _state_timer <= 0.0:
				state = State.CHASING
				_play("Run_Frantic")
		State.STUMBLING, State.ATTACKING:
			_state_timer -= delta
			_hold_in_place(delta)
			if _state_timer <= 0.0:
				state = State.CHASING
				_play("Run_Frantic")
		State.PATROL:
			_process_patrol(delta)
		State.SEARCHING:
			_process_search(delta)
		State.CHASING:
			_process_chase(delta)

# ------------------------------------------------------------------ patrulla
func _enter_patrol() -> void:
	state = State.PATROL
	_forced = false
	_pausing = false
	if not patrol_points.is_empty():
		var best := 0
		var best_d := INF
		for i in patrol_points.size():
			var d := global_position.distance_to(patrol_points[i])
			if d < best_d:
				best_d = d
				best = i
		_wp_index = best
	_play("Walk_Nervous")

func _process_patrol(delta: float) -> void:
	if _perceive():
		_on_spotted()
		return
	if patrol_points.is_empty():
		_hold_in_place(delta)
		_play("Idle_Watchful")
		return
	if _pausing:
		_state_timer -= delta
		_hold_in_place(delta)
		if _state_timer <= 0.0:
			_pausing = false
			_wp_index = (_wp_index + 1) % patrol_points.size()
			_play("Walk_Nervous")
		return
	var wp: Vector3 = patrol_points[_wp_index]
	if _flat_distance(wp) < 1.4:
		_pausing = true
		_state_timer = randf_range(2.0, 4.5)
		_play("Idle_Watchful")
		return
	_move_toward(wp, patrol_speed, delta)

# ------------------------------------------------------------------ busqueda
func _process_search(delta: float) -> void:
	if _perceive():
		_on_spotted()
		return
	if _search_looking:
		_state_timer -= delta
		_hold_in_place(delta)
		if _state_timer <= 0.0:
			_search_looking = false
			_enter_patrol()
		return
	_state_timer -= delta
	if _flat_distance(_last_known) < 1.6 or _state_timer <= 0.0:
		_search_looking = true
		_state_timer = 3.0
		_play("Idle_Watchful")
		return
	_move_toward(_last_known, search_speed, delta)

# ------------------------------------------------------------------ persecucion
func _process_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		stop_chase()
		return

	var dist := _flat_distance(target.global_position)
	if dist <= attack_range and _attack_timer <= 0.0:
		_start_attack()
		return

	var sees := _forced or _perceive()
	if sees:
		_lost_timer = 0.0
		_last_known = target.global_position
	else:
		_lost_timer += delta
		if _lost_timer > lose_time or dist > lose_range:
			state = State.SEARCHING
			_search_looking = false
			_state_timer = 8.0
			_play("Walk_Nervous")
			return

	var goal: Vector3 = target.global_position if sees else _last_known
	# Rubber-band de velocidad sin teletransporte: recupera terreno si el jugador
	# gana mucha distancia y afloja un poco cuando ya le respira en la nuca.
	var player_run_speed: float = _base_player_run_speed
	if _target_get_run_speed != null:
		player_run_speed = float(_target_get_run_speed.call())
	# La persecución debe presionar según la dificultad, pero dejar una ventana
	# de salida. En difícil/Lovecraft el Grapper alcanza al jugador al final de
	# una ruta limpia; tras el screamer vuelve a quedar varias celdas atrás.
	var lm := GameManager.GAMEPLAY.labyrinth
	var close_ratio: float = lm.chase_close_ratio.get(GameManager.difficulty_id, 0.82)
	var far_ratio: float = lm.chase_far_ratio.get(GameManager.difficulty_id, 0.94)
	var close_speed: float = player_run_speed * close_ratio
	var far_speed: float = minf(player_run_speed * far_ratio, chase_speed * 1.18)
	var pursuit_speed := lerpf(close_speed, far_speed, clampf((dist - lm.stumble_distance_threshold) / lm.stumble_distance_range, 0.0, 1.0))
	_move_toward(goal, pursuit_speed, delta, true)

# ------------------------------------------------------------------ deteccion
func _on_spotted() -> void:
	emit_signal("spotted_player")
	_last_known = target.global_position
	_lost_timer = 0.0
	if _scream_timer <= 0.0:
		_begin_scream()
	else:
		state = State.CHASING
		_play("Run_Frantic")

func _begin_scream() -> void:
	state = State.EMERGING
	_scream_timer = scream_cooldown
	_state_timer = _anim_length("Scream", 1.2)
	_play("Scream")
	if _scream_player != null:
		_scream_player.play()
	emit_signal("scream_started")

# ¿Te percibe? Por oido (segun el ruido que haces) o por vista (cono + linea de vista).
func _perceive() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var to_t: Vector3 = target.global_position - global_position
	to_t.y = 0.0
	var d := to_t.length()
	var noise := 0.0
	if target.has_method("get_noise_radius"):
		noise = target.get_noise_radius()
	if d <= noise * 0.6:
		return true                      # te oye aunque no te vea
	var rng := sight_range
	if target.has_method("is_crouching") and target.is_crouching():
		rng *= crouch_sight_factor
	if target.has_method("is_in_tall_grass") and target.is_in_tall_grass():
		rng *= grass_sight_factor
	if d > maxf(rng, noise):
		return false
	var fwd := Vector3(sin(facing_angle), 0.0, cos(facing_angle))
	if d > 3.0 and fwd.dot(to_t / d) < cos(deg_to_rad(sight_fov_deg * 0.5)):
		return false                     # fuera de su cono de vision (muy cerca, lo nota igual)
	return _has_line_of_sight()

func _has_line_of_sight() -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.5, 0), target.global_position + Vector3(0, 1.0, 0))
	q.exclude = _exclusions()
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _exclusions() -> Array[RID]:
	var ex: Array[RID] = [get_rid()]
	if target is CollisionObject3D:
		ex.append(target.get_rid())
	return ex

# ------------------------------------------------------------------ movimiento
func _flat_distance(p: Vector3) -> float:
	var v := p - global_position
	v.y = 0.0
	return v.length()

func _face_target(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var to_t: Vector3 = target.global_position - global_position
	if Vector2(to_t.x, to_t.z).length() > 0.01:
		facing_angle = lerp_angle(facing_angle, atan2(to_t.x, to_t.z), clampf(turn_speed * delta, 0.0, 1.0))
		rotation.y = facing_angle

# Cuando NO avanza (gritando, tropezado, atacando, mirando): sigue pegado al piso.
func _hold_in_place(delta: float) -> void:
	_apply_gravity(delta)
	velocity = Vector3(0, vertical_velocity, 0)
	move_and_slide()

func _move_toward(point: Vector3, speed: float, delta: float, check_stumble: bool = false) -> void:
	var movement_goal := point
	if get_parent() != null and get_parent().is_in_group("maze_navigation"):
		movement_goal = _maze_waypoint_toward(point, delta)
	var to_p := movement_goal - global_position
	to_p.y = 0.0
	if to_p.length() > 0.01:
		var dir := _steer(to_p.normalized())
		facing_angle = lerp_angle(facing_angle, atan2(dir.x, dir.z), clampf(turn_speed * delta, 0.0, 1.0))
		rotation.y = facing_angle
	var move_dir := Vector3(sin(facing_angle), 0.0, cos(facing_angle))
	_apply_gravity(delta)
	velocity = Vector3(move_dir.x * speed, vertical_velocity, move_dir.z * speed)
	move_and_slide()
	# Si casi no avanzo, choco de frente: a veces tropieza (te da aire para escapar).
	if check_stumble:
		var real := Vector2(velocity.x, velocity.z).length()
		if real < speed * 0.25 and _stumble_cooldown <= 0.0 and randf() < stumble_chance:
			_start_stumble()

func _maze_waypoint_toward(goal: Vector3, delta: float) -> Vector3:
	_maze_nav_timer -= delta
	if _maze_nav_timer <= 0.0 or _maze_goal.distance_to(goal) > 2.0 or _maze_path.is_empty():
		_maze_nav_timer = 0.55
		_maze_goal = goal
		var maze_room = get_parent().get_node_or_null("Room_laberinto")
		if maze_room != null and maze_room.has_method("get_maze_navigation") and _astar_grid != null:
			var nav: Dictionary = maze_room.get_maze_navigation()
			var world_to_cell: Callable = nav.world_to_cell
			var cell_to_world: Callable = nav.cell_to_world
			var from_cell: Vector2i = world_to_cell.call(global_position)
			var to_cell: Vector2i = world_to_cell.call(goal)
			# Use member AStarGrid2D instead of recreating (BUG-003)
			var path_ids: Array[Vector2i] = _astar_grid.get_id_path(from_cell, to_cell)
			if path_ids.size() > 1:
				_maze_path = path_ids.duplicate()
				_maze_path_index = 1
				return _get_next_waypoint_from_cells(path_ids, 1)
		# Fallback: direct line if no nav
		return goal
	if _maze_path.size() <= 1:
		return goal
	return _get_next_waypoint_from_cells(_maze_path, _maze_path_index)


func _get_next_waypoint_from_cells(path_cells: Array[Vector2i], index: int) -> Vector3:
	if path_cells.size() <= 1:
		return Vector3.INF
	var maze_room = get_parent().get_node_or_null("Room_laberinto")
	var cell_size := GameManager.GAMEPLAY.labyrinth.cell_size
	if maze_room != null and maze_room.has("_maze_cell_size"):
		cell_size = maze_room._maze_cell_size
	var half := GameManager.GAMEPLAY.labyrinth.world_size * 0.5

	while index < path_cells.size() - 1:
		var cell := path_cells[index]
		var current_point := Vector3(-half + (float(cell.x) + 0.5) * cell_size, global_position.y, half - (float(cell.y) + 0.5) * cell_size)
		if (current_point - global_position).length() > 1.0:
			_maze_path_index = index
			return current_point
		index += 1
	_maze_path_index = path_cells.size() - 1
	var last_cell := path_cells[path_cells.size() - 1]
	return Vector3(-half + (float(last_cell.x) + 0.5) * cell_size, global_position.y, half - (float(last_cell.y) + 0.5) * cell_size)

# Esquiva obstaculos: si hay algo adelante, prueba desviarse a un lado.
func _steer(dir: Vector3) -> Vector3:
	var origin := global_position + Vector3(0, 0.9, 0)
	var offsets: Array = [0.0, 35.0, -35.0, 70.0, -70.0, 110.0, -110.0]
	if _steer_sign < 0.0:
		offsets = [0.0, -35.0, 35.0, -70.0, 70.0, -110.0, 110.0]
	for off in offsets:
		var d := dir.rotated(Vector3.UP, deg_to_rad(off))
		var q := PhysicsRayQueryParameters3D.create(origin, origin + d * GameManager.GAMEPLAY.labyrinth.cell_size)
		q.exclude = _exclusions()
		if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			if off != 0.0:
				_steer_sign = signf(off)
			return d
	return dir

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		vertical_velocity = -0.5
	else:
		vertical_velocity += gravity * delta

# ------------------------------------------------------------------ ataque y tropiezo
func _start_attack() -> void:
	state = State.ATTACKING
	_attack_timer = attack_cooldown
	_state_timer = _anim_length("Attack_Lunge", 0.9)
	_play("Attack_Lunge")
	emit_signal("player_caught", target)
	# Castigo provisional: un golpe fuerte de cordura. Facil de cambiar despues
	# (jumpscare, reinicio de posicion...) sin tocar el resto del monstruo.
	GameManager.drain_sanity(attack_sanity_damage)
	GameManager.show_message("¡Te atrapó!", "", "", true)

func _start_stumble() -> void:
	state = State.STUMBLING
	_state_timer = stumble_duration
	_stumble_cooldown = stumble_cooldown_time
	_play("WallSlam_Recover")
	emit_signal("stumbled")

# ------------------------------------------------------------------ animaciones
func _find_anim_player():
	if mesh_root == null:
		return null
	for child in mesh_root.get_children():
		if child is AnimationPlayer:
			return child
		for grandchild in child.get_children():
			if grandchild is AnimationPlayer:
				return grandchild
	return null

func _norm(s: String) -> String:
	var out := ""
	for c in s.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
	return out

# Los nombres llegan del FBX como "MonsterPSX_Rig|Scream.lol" y Godot 4 puede
# cambiarlos (| -> _ o '/'). Se busca ignorando simbolos y mayusculas.
func _resolve_anim(short_name: String) -> String:
	if _anim_cache.has(short_name):
		return _anim_cache[short_name]
	var resolved := ""
	if anim_player != null:
		var want := _norm(short_name)
		for existing in anim_player.get_animation_list():
			if _norm(existing) == want:
				resolved = existing
				break
		if resolved == "":
			for existing in anim_player.get_animation_list():
				if _norm(existing).ends_with(want):
					resolved = existing
					break
		if resolved == "":
			for existing in anim_player.get_animation_list():
				if _norm(existing).contains(want):
					resolved = existing
					break
	_anim_cache[short_name] = resolved
	return resolved

# Godot 4 importa las animaciones sin repetirse: caminar/correr/quieto deben ir en bucle.
func _configure_loops() -> void:
	if anim_player == null:
		return
	for n in anim_player.get_animation_list():
		var low := _norm(n)
		var anim: Animation = anim_player.get_animation(n)
		if low.contains("idle") or low.contains("walk") or low.contains("run"):
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE

func _play(short_name: String) -> void:
	if anim_player == null:
		return
	var resolved := _resolve_anim(short_name)
	if resolved != "" and anim_player.current_animation != resolved:
		anim_player.play(resolved, 0.2)

func _anim_length(short_name: String, fallback: float) -> float:
	if anim_player == null:
		return fallback
	var resolved := _resolve_anim(short_name)
	if resolved == "":
		return fallback
	return anim_player.get_animation(resolved).length
