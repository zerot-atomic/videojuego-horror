extends Node3D

const WrapperScene := preload("res://scenes3d/Wrapper3D.tscn")
const ExitScript := preload("res://scripts3d/ExitArea3D.gd")
const ScreamerScene := preload("res://scenes3d/ScreamerOverlay.tscn")
const TreeRt1 := preload("res://art3d/props_extra/trees/tree_rt_1.glb")
const TreeRt2 := preload("res://art3d/props_extra/trees/tree_rt_2.glb")
const TreeRt3 := preload("res://art3d/props_extra/trees/tree_rt_3.glb")
const TreeRt4 := preload("res://art3d/props_extra/trees/tree_rt_4.glb")
const DeadTreeRt1 := preload("res://art3d/props_extra/trees/dead_tree_rt_1.glb")
const NatureStump := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_stump_01.glb")
const NatureMushrooms := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_mushrooms_01.glb")
const NatureRockMossy := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_rock_mossy_01.glb")
const Fence01 := preload("res://art3d/extras/AloneInTheDusk/Fence_01.glb")

var _maze_cols: int
var _maze_rows: int
var _maze_cell_size: float
var _maze_start_cell: Vector2i
var _maze_exit_cell: Vector2i
var _maze_adjacency: Dictionary = {}
var _maze_seed: int
var _path_cache: Dictionary = {}
var _wall_meshes: Array[Mesh] = []
var _floor_mesh: Mesh

func _ready() -> void:
	add_to_group("maze_navigation")
	_init_config()
	_build_lighting_only()
	_build_maze()
	_build_spawns()
	_build_exits()
	_build_lights()
	_build_ambient_decor()
	var screamer := ScreamerScene.instantiate()
	add_child(screamer)
	var grapper := WrapperScene.instantiate()
	grapper.name = "Wrapper3D"
	var spawn_cell := _pick_grapper_spawn_cell()
	grapper.position = cell_to_world(spawn_cell) + Vector3(0, 1.0, 0)
	grapper.player_caught.connect(_on_grapper_caught.bind(grapper, screamer))
	add_child(grapper)

func _init_config() -> void:
	var lm := GameManager.GAMEPLAY.labyrinth
	var diff := GameManager.difficulty_id
	var diff_cfg: Dictionary = lm.difficulty_config.get(diff, lm.difficulty_config["normal"])
	_maze_cols = diff_cfg.cols
	_maze_rows = diff_cfg.rows
	_maze_seed = diff_cfg.seed
	_maze_cell_size = lm.world_size / float(_maze_cols)
	_maze_start_cell = Vector2i(int(_maze_cols / 2), _maze_rows - 1)
	_maze_exit_cell = Vector2i(int(_maze_cols / 2), 0)
	_path_cache.clear()

func _build_lighting_only() -> void:
	# Floor at y=0, top face at y=0 (no fog — Zone3D._apply_zone_fog is single source)
	var floor_node := StaticBody3D.new()
	floor_node.name = "SueloLaberinto"
	_floor_mesh = _make_floor_mesh()
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = _floor_mesh
	floor_mi.material_override = _floor_mat()
	floor_node.add_child(floor_mi)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(GameManager.GAMEPLAY.labyrinth.world_size, 0.1, GameManager.GAMEPLAY.labyrinth.world_size)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, -0.05, 0)
	floor_node.add_child(floor_col)
	add_child(floor_node)

func _make_floor_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	var uv_scale := GameManager.GAMEPLAY.labyrinth.world_size / 2.0
	# Quad at y=0
	st.set_uv(Vector2(-half, -half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(-half, 0.0, -half))
	st.set_uv(Vector2(half, -half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(half, 0.0, -half))
	st.set_uv(Vector2(half, half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(half, 0.0, half))
	st.set_uv(Vector2(-half, -half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(-half, 0.0, -half))
	st.set_uv(Vector2(half, half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(half, 0.0, half))
	st.set_uv(Vector2(-half, half) / uv_scale + Vector2(0.5, 0.5)); st.add_vertex(Vector3(-half, 0.0, half))
	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _floor_mat() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://art3d/classic64_pack/Ground/Materials/dirt_02.png")
	material.roughness = 0.95
	return material

func _build_maze() -> void:
	var wall_h := GameManager.GAMEPLAY.labyrinth.wall_height
	var wall_t := GameManager.GAMEPLAY.labyrinth.wall_thickness
	var wall_mat := _wall_mat()
	_build_maze_connections(_maze_seed)
	_prepare_wall_meshes()

	# Perimeter walls - full height, base at y=0
	var half_w := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	_add_wall_static(Vector3(-half_w, wall_h * 0.5, 0.0), Vector3(wall_t, wall_h, GameManager.GAMEPLAY.labyrinth.world_size), wall_mat, "PerimetroOeste")
	_add_wall_static(Vector3(half_w, wall_h * 0.5, 0.0), Vector3(wall_t, wall_h, GameManager.GAMEPLAY.labyrinth.world_size), wall_mat, "PerimetroEste")
	_add_wall_static(Vector3(0.0, wall_h * 0.5, -half_w), Vector3(GameManager.GAMEPLAY.labyrinth.world_size, wall_h, wall_t), wall_mat, "PerimetroSur")
	_add_wall_static(Vector3(0.0, wall_h * 0.5, half_w), Vector3(GameManager.GAMEPLAY.labyrinth.world_size, wall_h, wall_t), wall_mat, "PerimetroNorte")

	# Boundary openings aligned with cell centers
	_add_boundary_opening(-half_w, _maze_cell_center(_maze_start_cell).x, wall_mat, wall_t, wall_h, "Entrada")
	_add_boundary_opening(half_w, _maze_cell_center(_maze_exit_cell).x, wall_mat, wall_t, wall_h, "Salida")

	# Internal walls - base at y=0, full height (wall_h * 0.5 center like perimeter)
	var wall_center_y := wall_h * 0.5
	for y in range(_maze_rows):
		for x in range(_maze_cols):
			var cell := Vector2i(x, y)
			var center := _maze_cell_center(cell)
			if y > 0 and not _maze_adjacency[cell].has(cell + Vector2i.UP):
				var wall_pos := center + Vector3(0.0, wall_center_y, _maze_cell_size * 0.5)
				_add_wall_static(wall_pos, Vector3(_maze_cell_size + wall_t, wall_h, wall_t), wall_mat, "TabiqueH_%02d_%02d" % [x, y])
			if x > 0 and not _maze_adjacency[cell].has(cell + Vector2i.LEFT):
				var wall_pos := center + Vector3(-_maze_cell_size * 0.5, wall_center_y, 0.0)
				_add_wall_static(wall_pos, Vector3(wall_t, wall_h, _maze_cell_size + wall_t), wall_mat, "TabiqueV_%02d_%02d" % [x, y])

func _prepare_wall_meshes() -> void:
	_wall_meshes.clear()
	var wall_t := GameManager.GAMEPLAY.labyrinth.wall_thickness
	var wall_h := GameManager.GAMEPLAY.labyrinth.wall_height
	var cell_s := _maze_cell_size
	# Perimeter
	_wall_meshes.append(_make_box_mesh(Vector3(wall_t, wall_h, GameManager.GAMEPLAY.labyrinth.world_size)))
	# Boundary opening segments (variable width)
	# Internal horizontal
	_wall_meshes.append(_make_box_mesh(Vector3(cell_s + wall_t, wall_h, wall_t)))
	# Internal vertical
	_wall_meshes.append(_make_box_mesh(Vector3(wall_t, wall_h, cell_s + wall_t)))

func _make_box_mesh(size: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var verts: Array[Vector3] = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz),
		Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz),
	]
	var faces := [
		[0,1,2, 0,2,3], [4,5,6, 4,6,7], [0,1,5, 0,5,4],
		[2,3,7, 2,7,6], [1,2,6, 1,6,5], [0,3,7, 0,7,4],
	]
	for f in faces:
		var n: Vector3 = (verts[f[1]] - verts[f[0]]).cross(verts[f[2]] - verts[f[0]]).normalized()
		for i in f:
			st.set_normal(n); st.add_vertex(verts[i])
	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _build_maze_connections(maze_seed: int) -> void:
	_maze_adjacency.clear()
	for y in range(_maze_rows):
		for x in range(_maze_cols):
			_maze_adjacency[Vector2i(x, y)] = []
	var visited: Dictionary = {_maze_start_cell: true}
	var stack: Array[Vector2i] = [_maze_start_cell]
	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var choices: Array[Vector2i] = []
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate: Vector2i = current + offset
			if candidate.x >= 0 and candidate.x < _maze_cols and candidate.y >= 0 and candidate.y < _maze_rows and not visited.has(candidate):
				choices.append(candidate)
		if choices.is_empty():
			stack.pop_back()
			continue
		var current_cell := current
		var seed_val := maze_seed
		choices.sort_custom(func(a: Vector2i, b: Vector2i) -> int:
			var pa := _neighbor_priority(current_cell, a, seed_val)
			var pb := _neighbor_priority(current_cell, b, seed_val)
			return pa - pb
		)
		var next: Vector2i = choices[0]
		_maze_adjacency[current].append(next)
		_maze_adjacency[next].append(current)
		visited[next] = true
		stack.append(next)
	# Add loops for evasion (not perfect maze)
	_add_maze_loops(maze_seed)
	var route := _maze_route_cells()
	var directions: Array[String] = []
	for i in range(1, route.size()):
		var step: Vector2i = route[i] - route[i - 1]
		directions.append("N" if step == Vector2i.UP else "S" if step == Vector2i.DOWN else "E" if step == Vector2i.RIGHT else "O")
	print("[Laberinto] ", GameManager.difficulty_id, " ruta (N/S/E/O): ", "-".join(directions), " bucles: ", _count_loops())

func _add_maze_loops(seed: int) -> void:
	# Add extra connections to create loops (15-25% of possible walls removed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 997
	var extra_connections := int(_maze_cols * _maze_rows * 0.2)
	var attempts := 0
	while extra_connections > 0 and attempts < extra_connections * 5:
		attempts += 1
		var x := rng.randi_range(0, _maze_cols - 1)
		var y := rng.randi_range(0, _maze_rows - 1)
		var cell := Vector2i(x, y)
		var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		dirs.shuffle()
		for d in dirs:
			var n: Vector2i = cell + d
			if n.x >= 0 and n.x < _maze_cols and n.y >= 0 and n.y < _maze_rows:
				if not _maze_adjacency[cell].has(n) and rng.randi() % 4 == 0:
					_maze_adjacency[cell].append(n)
					_maze_adjacency[n].append(cell)
					extra_connections -= 1
					break

func _count_loops() -> int:
	var edges := 0
	for cell in _maze_adjacency:
		edges += _maze_adjacency[cell].size()
	edges = edges / 2
	var vertices := _maze_cols * _maze_rows
	return edges - vertices + 1

func _neighbor_priority(from: Vector2i, to: Vector2i, seed: int) -> int:
	var delta := to - from
	var direction_rank := 0 if delta == Vector2i.UP else 1 if delta == Vector2i.RIGHT else 2 if delta == Vector2i.DOWN else 3
	var cell_rank := posmod((to.x + 1) * 17 + (to.y + 1) * 31 + (to.x + 3) * (to.y + 5) * 7 + seed * 13, 997)
	return cell_rank * 4 + direction_rank

func _maze_route_cells() -> Array[Vector2i]:
	var route_start := _maze_exit_cell
	var route_end := _maze_start_cell
	var queue: Array[Vector2i] = [route_start]
	var previous: Dictionary = {route_start: route_start}
	var index := 0
	while index < queue.size() and not previous.has(route_end):
		var cell: Vector2i = queue[index]
		index += 1
		for next: Vector2i in _maze_adjacency[cell]:
			if not previous.has(next):
				previous[next] = cell
				queue.append(next)
	var route: Array[Vector2i] = []
	if not previous.has(route_end):
		return route
	var cursor := route_end
	while cursor != route_start:
		route.push_front(cursor)
		cursor = previous[cursor]
	route.push_front(route_start)
	return route

func _maze_cell_center(cell: Vector2i) -> Vector3:
	var half := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	return Vector3(-half + (float(cell.x) + 0.5) * _maze_cell_size, 0.0, half - (float(cell.y) + 0.5) * _maze_cell_size)

func _add_boundary_opening(z: float, opening_x: float, material: Material, wall_t: float, wall_h: float, label: String) -> void:
	var half_gap := maxf(wall_t * 2.0, _maze_cell_size * 0.35)
	var left_width := opening_x - half_gap + GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	var right_width := GameManager.GAMEPLAY.labyrinth.world_size * 0.5 - opening_x - half_gap
	if left_width > wall_t:
		_add_wall_static(Vector3(-GameManager.GAMEPLAY.labyrinth.world_size * 0.5 + left_width * 0.5, wall_h * 0.5, z), Vector3(left_width, wall_h, wall_t), material, label + "Oeste")
	if right_width > wall_t:
		_add_wall_static(Vector3(opening_x + half_gap + right_width * 0.5, wall_h * 0.5, z), Vector3(right_width, wall_h, wall_t), material, label + "Este")

func _add_wall_static(at: Vector3, dimensions: Vector3, material: Material, node_name: String) -> void:
	var wall := StaticBody3D.new()
	wall.name = node_name
	wall.position = at
	var mi := MeshInstance3D.new()
	# Pick closest pre-made mesh
	var best_idx := 0
	var best_diff := INF
	for i in _wall_meshes.size():
		var ms := _wall_meshes[i].get_aabb().size
		var diff := (ms - dimensions).abs().length()
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	mi.mesh = _wall_meshes[best_idx]
	mi.material_override = material
	mi.scale = Vector3(dimensions.x / _wall_meshes[best_idx].get_aabb().size.x,
					   dimensions.y / _wall_meshes[best_idx].get_aabb().size.y,
					   dimensions.z / _wall_meshes[best_idx].get_aabb().size.z)
	wall.add_child(mi)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	col.shape = box
	wall.add_child(col)
	add_child(wall)

func _wall_mat() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.10, 0.14)
	material.roughness = 0.9
	material.emission_enabled = true
	material.emission = Color(0.04, 0.02, 0.06)
	material.emission_energy_multiplier = 0.35
	return material

func _build_spawns() -> void:
	# SpawnDesdeBosque: at z=+30 boundary, facing inward (negative Z / PI)
	var forest_spawn := Marker3D.new()
	forest_spawn.name = "SpawnDesdeBosque"
	var exit_center := _maze_cell_center(_maze_exit_cell)
	forest_spawn.position = exit_center + Vector3(0.0, 0.1, GameManager.GAMEPLAY.labyrinth.exit_spawn_offset)
	forest_spawn.rotation.y = PI
	add_child(forest_spawn)

	# SpawnDesdeCampo: at z=-30 boundary, facing inward (positive Z / 0)
	var field_spawn := Marker3D.new()
	field_spawn.name = "SpawnDesdeCampo"
	var start_center := _maze_cell_center(_maze_start_cell)
	field_spawn.position = start_center + Vector3(0.0, 0.1, -GameManager.GAMEPLAY.labyrinth.exit_spawn_offset)
	field_spawn.rotation.y = 0.0
	add_child(field_spawn)

func _build_exits() -> void:
	var exit_w := GameManager.GAMEPLAY.labyrinth.exit_width
	var exit_h := GameManager.GAMEPLAY.labyrinth.exit_height
	var exit_d := GameManager.GAMEPLAY.labyrinth.exit_depth
	var half_w := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	# SalidaAlCampo at z=-30 (south wall), trigger AT the wall opening
	var start_pos := _maze_cell_center(_maze_start_cell)
	_add_exit("SalidaAlCampo", Vector3(start_pos.x, exit_h * 0.5, -half_w), "campo_cultivo", exit_w, exit_h, exit_d)
	# SalidaAlBosque at z=+30 (north wall), trigger AT the wall opening
	var exit_pos := _maze_cell_center(_maze_exit_cell)
	_add_exit("SalidaAlBosque", Vector3(exit_pos.x, exit_h * 0.5, half_w), "bosque", exit_w, exit_h, exit_d)

func _add_exit(node_name: String, at: Vector3, target: String, w: float, h: float, d: float) -> void:
	var area := Area3D.new()
	area.name = node_name
	area.position = at
	area.set_script(ExitScript)
	area.set("target_zone", target)
	area.set("spawn_marker", "SpawnDesdeCampo" if target == "campo_cultivo" else "SpawnDesdeBosque")
	add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, d)
	shape.shape = box
	area.add_child(shape)

func _build_lights() -> void:
	var lm := GameManager.GAMEPLAY.labyrinth
	# Single fill light
	var fill := OmniLight3D.new()
	fill.name = "LuzRelleno"
	fill.position = Vector3(0.0, lm.light_fill_height, 0.0)
	fill.light_color = lm.light_fill_color
	fill.light_energy = lm.light_fill_energy
	fill.omni_range = lm.light_fill_range
	fill.shadow_enabled = false
	add_child(fill)
	# Dead-end markers (emissive spores on floor, no extra lights)
	# Path guidance: subtle emissive strips on floor at key junctions
	_place_dead_end_markers()
	_place_junction_guides()

func _place_dead_end_markers() -> void:
	var mat := _spore_mat()
	var count := 0
	for y in range(_maze_rows):
		for x in range(_maze_cols):
			var cell := Vector2i(x, y)
			var conns: int = _maze_adjacency[cell].size()
			if conns == 1 and count < GameManager.GAMEPLAY.labyrinth.max_dead_end_markers:
				var pos := _maze_cell_center(cell)
				var marker := MeshInstance3D.new()
				marker.name = "MarcadorCallejon_%02d" % count
				marker.mesh = _make_spore_mesh()
				marker.material_override = mat
				marker.position = pos + Vector3(0, 0.15, 0)
				marker.scale = Vector3(0.6, 0.6, 0.6)
				add_child(marker)
				count += 1

func _place_junction_guides() -> void:
	var mat := _guide_mat()
	var count := 0
	for y in range(_maze_rows):
		for x in range(_maze_cols):
			var cell := Vector2i(x, y)
			var conns: int = _maze_adjacency[cell].size()
			if conns >= 3 and count < GameManager.GAMEPLAY.labyrinth.max_junction_guides:
				var pos := _maze_cell_center(cell)
				var guide := MeshInstance3D.new()
				guide.name = "GuiaCruce_%02d" % count
				guide.mesh = _make_guide_mesh()
				guide.material_override = mat
				guide.position = pos + Vector3(0, 0.05, 0)
				guide.scale = Vector3(0.8, 0.1, 0.8)
				add_child(guide)
				count += 1

func _make_spore_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color := Color(0.4, 0.1, 0.7)
	for angle in [0.0, PI * 2.0 / 3.0, PI * 4.0 / 3.0]:
		var v0 := Vector3(0, 0.5, 0)
		var v1 := Vector3(cos(angle) * 0.25, -0.1, sin(angle) * 0.25)
		var v2 := Vector3(cos(angle + PI/3.0) * 0.25, -0.1, sin(angle + PI/3.0) * 0.25)
		st.set_color(color); st.add_vertex(v0)
		st.set_color(color); st.add_vertex(v1)
		st.set_color(color); st.add_vertex(v2)
	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _make_guide_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(Vector3(-0.5, 0, -0.5))
	st.add_vertex(Vector3(0.5, 0, -0.5))
	st.add_vertex(Vector3(0.5, 0, 0.5))
	st.add_vertex(Vector3(-0.5, 0, -0.5))
	st.add_vertex(Vector3(0.5, 0, 0.5))
	st.add_vertex(Vector3(-0.5, 0, 0.5))
	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _spore_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.05, 0.35)
	m.emission_enabled = true
	m.emission = Color(0.5, 0.1, 0.8)
	m.emission_energy_multiplier = 1.2
	m.roughness = 0.3
	return m

func _guide_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.15, 0.1, 0.25)
	m.emission_enabled = true
	m.emission = Color(0.3, 0.2, 0.5)
	m.emission_energy_multiplier = 0.6
	m.roughness = 0.8
	return m

func _build_ambient_decor() -> void:
	# RoomSetDressing handles base dressing via _dress_maze()
	# Add extra corrupt vegetation using actual assets
	var rng := RandomNumberGenerator.new()
	rng.seed = _maze_seed + 1234
	var dead_trees := [DeadTreeRt1]
	var trees := [TreeRt1, TreeRt2, TreeRt3, TreeRt4]
	var stumps := [NatureStump]
	var mushrooms := [NatureMushrooms]
	var rocks := [NatureRockMossy]
	# Place dead trees near perimeter (corrupted forest bleeding in)
	for i in range(GameManager.GAMEPLAY.labyrinth.ambient_dead_trees):
		var side := rng.randi_range(0, 3)
		var x: float
		var z: float
		match side:
			0: x = rng.randf_range(-29.0, -25.0); z = rng.randf_range(-28.0, 28.0)
			1: x = rng.randf_range(25.0, 29.0); z = rng.randf_range(-28.0, 28.0)
			2: x = rng.randf_range(-28.0, 28.0); z = rng.randf_range(-29.0, -25.0)
			3: x = rng.randf_range(-28.0, 28.0); z = rng.randf_range(25.0, 29.0)
		_place_asset(dead_trees[0], "ArbolMuerto_%02d" % i, Vector3(x, 0, z), rng.randf_range(0.7, 1.0))
	# Stumps and mushrooms in dead-ends
	var dead_ends := []
	for y in range(_maze_rows):
		for x in range(_maze_cols):
			var cell := Vector2i(x, y)
			if _maze_adjacency[cell].size() == 1:
				dead_ends.append(cell)
	dead_ends.shuffle()
	for i in range(min(GameManager.GAMEPLAY.labyrinth.ambient_stumps, dead_ends.size())):
		var pos := _maze_cell_center(dead_ends[i])
		_place_asset(stumps[0], "Tocon_%02d" % i, pos + Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5)), rng.randf_range(0.8, 1.2))
	for i in range(min(GameManager.GAMEPLAY.labyrinth.ambient_mushrooms, dead_ends.size())):
		var pos := _maze_cell_center(dead_ends[i])
		_place_asset(mushrooms[0], "Hongos_%02d" % i, pos + Vector3(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8)), rng.randf_range(0.5, 0.8))
	# Rocks scattered
	for i in range(GameManager.GAMEPLAY.labyrinth.ambient_rocks):
		var x := rng.randf_range(-28.0, 28.0)
		var z := rng.randf_range(-28.0, 28.0)
		_place_asset(rocks[0], "RocaMoho_%02d" % i, Vector3(x, 0, z), rng.randf_range(0.6, 1.0))

func _place_asset(scene: PackedScene, name: String, at: Vector3, scale: float) -> void:
	var inst := scene.instantiate() as Node3D
	inst.name = name
	inst.position = at
	inst.scale = Vector3.ONE * scale
	inst.rotation.y = randf_range(0.0, TAU)
	add_child(inst)

func _pick_grapper_spawn_cell() -> Vector2i:
	var player_cell := _maze_start_cell if GameManager.previous_zone_id == "campo_cultivo" else _maze_exit_cell
	var distances: Dictionary = {player_cell: 0}
	var queue: Array[Vector2i] = [player_cell]
	var index := 0
	while index < queue.size():
		var cell: Vector2i = queue[index]
		index += 1
		for next: Vector2i in _maze_adjacency.get(cell, []):
			if not distances.has(next):
				distances[next] = int(distances[cell]) + 1
				queue.append(next)
	var min_dist := GameManager.GAMEPLAY.labyrinth.grapper_min_distance_cells
	var candidates: Array[Vector2i] = []
	for cell in distances:
		if int(distances[cell]) >= min_dist:
			var world_pos := cell_to_world(cell)
			if _is_clear_spawn(world_pos):
				candidates.append(cell)
	if candidates.is_empty():
		# Fallback: any cell at max distance
		var max_d := 0
		for cell in distances:
			if int(distances[cell]) > max_d:
				max_d = int(distances[cell])
		for cell in distances:
			if int(distances[cell]) == max_d:
				var world_pos := cell_to_world(cell)
				if _is_clear_spawn(world_pos):
					return cell
		return _maze_exit_cell if GameManager.previous_zone_id != "campo_cultivo" else _maze_start_cell
	# Pick furthest candidate
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return int(distances[b]) < int(distances[a])
	)
	return candidates[0]

func _is_clear_spawn(pos: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var probe := SphereShape3D.new()
	probe.radius = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 1.5, 0))
	query.collision_mask = 1
	if not space.intersect_shape(query, 1).is_empty():
		return false
	# Ensure minimum distance from perimeter walls (1.5m clearance)
	var half_w := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	var margin := 1.5
	if pos.x < -half_w + margin or pos.x > half_w - margin:
		return false
	if pos.z < -half_w + margin or pos.z > half_w - margin:
		return false
	return true

# ==================== PUBLIC NAVIGATION API ====================

func world_to_cell(world_pos: Vector3) -> Vector2i:
	var half := GameManager.GAMEPLAY.labyrinth.world_size * 0.5
	var x := clampi(floori((world_pos.x + half) / _maze_cell_size), 0, _maze_cols - 1)
	var y := clampi(floori((half - world_pos.z) / _maze_cell_size), 0, _maze_rows - 1)
	return Vector2i(x, y)

func cell_to_world(cell: Vector2i) -> Vector3:
	return _maze_cell_center(cell)

func shortest_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var key := "%d,%d->%d,%d" % [from_cell.x, from_cell.y, to_cell.x, to_cell.y]
	if _path_cache.has(key):
		return _path_cache[key]
	var path := _bfs_path(from_cell, to_cell)
	_path_cache[key] = path
	return path

func _bfs_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var queue: Array[Vector2i] = [start]
	var prev: Dictionary = {start: start}
	var idx := 0
	while idx < queue.size() and not prev.has(goal):
		var cell := queue[idx]
		idx += 1
		for next in _maze_adjacency.get(cell, []):
			if not prev.has(next):
				prev[next] = cell
				queue.append(next)
	if not prev.has(goal):
		return []
	var path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = prev[cursor]
	path.push_front(start)
	return path

func is_cell_clear(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= _maze_cols or cell.y < 0 or cell.y >= _maze_rows:
		return false
	var pos := cell_to_world(cell)
	var space := get_world_3d().direct_space_state
	var probe := SphereShape3D.new()
	probe.radius = 0.4
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 0.5, 0))
	query.collision_mask = 1
	return space.intersect_shape(query, 1).is_empty()

func get_maze_navigation() -> Dictionary:
	return {
		"adjacency": _maze_adjacency,
		"cell_size": _maze_cell_size,
		"cols": _maze_cols,
		"rows": _maze_rows,
		"start_cell": _maze_start_cell,
		"exit_cell": _maze_exit_cell,
		"world_to_cell": world_to_cell.bind(),
		"cell_to_world": cell_to_world.bind(),
		"shortest_path": shortest_path.bind(),
		"is_cell_clear": is_cell_clear.bind(),
	}

func _on_grapper_caught(player: Node3D, grapper: Node3D, screamer: Node) -> void:
	if not is_instance_valid(player) or not is_instance_valid(grapper):
		return
	screamer.trigger()
	await get_tree().create_timer(1.05).timeout
	if not is_instance_valid(player) or not is_instance_valid(grapper):
		return
	grapper.global_position = _safe_grapper_position(player, grapper)
	grapper.velocity = Vector3.ZERO
	grapper.start_chase(player, false, true)

func _safe_grapper_position(player: Node3D, grapper: Node3D) -> Vector3:
	var player_cell := world_to_cell(player.global_position)
	var distances: Dictionary = {player_cell: 0}
	var queue: Array[Vector2i] = [player_cell]
	var index := 0
	while index < queue.size():
		var cell: Vector2i = queue[index]
		index += 1
		for next: Vector2i in _maze_adjacency.get(cell, []):
			if not distances.has(next):
				distances[next] = int(distances[cell]) + 1
				queue.append(next)
	var forward := Vector3(sin(player.rotation.y), 0.0, cos(player.rotation.y))
	var backward := -forward
	var preferred: Array[Vector2i] = []
	for wanted in [7, 8, 6, 9, 5, 10]:
		var layer: Array[Vector2i] = []
		for cell in distances:
			if int(distances[cell]) == wanted:
				layer.append(cell)
		layer.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var a_dir := cell_to_world(a) - player.global_position
			var b_dir := cell_to_world(b) - player.global_position
			a_dir.y = 0.0; b_dir.y = 0.0
			return backward.dot(a_dir.normalized()) > backward.dot(b_dir.normalized())
		)
		preferred.append_array(layer)
	var space := get_world_3d().direct_space_state
	var probe := SphereShape3D.new()
	probe.radius = 1.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid(), grapper.get_rid()]
	for cell in preferred:
		var candidate := cell_to_world(cell) + Vector3(0, 1.5, 0)
		query.transform = Transform3D(Basis.IDENTITY, candidate)
		if space.intersect_shape(query, 1).is_empty():
			return candidate
	# Fallback
	for d in [7, 8, 6, 9, 5, 10, 4, 11]:
		for cell in distances:
			if int(distances[cell]) == d:
				var candidate := cell_to_world(cell) + Vector3(0, 1.5, 0)
				query.transform = Transform3D(Basis.IDENTITY, candidate)
				if space.intersect_shape(query, 1).is_empty():
					return candidate
	return grapper.global_position