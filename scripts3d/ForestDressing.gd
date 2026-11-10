extends Node3D
# Disposición contenida y repetible del bosque. Los GLB ya convierten su eje
# local al importar, así que el giro aquí es solo para variar la silueta.
const TREES: Array[PackedScene] = [
	preload("res://art3d/retro_tree_pack/tree_rt_2.glb"),
	preload("res://art3d/retro_tree_pack/tree_rt_3.glb"),
	preload("res://art3d/retro_tree_pack/tree_rt_4.glb"),
	preload("res://art3d/retro_tree_pack/dead_tree_rt_1.glb"),
	preload("res://art3d/retro_tree_pack/dead_tree_rt_2.glb"),
]
const SMALL_TREE: PackedScene = preload("res://art3d/retro_tree_pack/small_tree_rt_1.glb")
const BUSHES: Array[PackedScene] = [
	preload("res://art3d/classic64_pack/Nature/bush_01.glb"),
	preload("res://art3d/classic64_pack/Nature/bush_02.glb"),
	preload("res://art3d/classic64_pack/Nature/bush_03.glb"),
	preload("res://art3d/classic64_pack/Nature/bush_04.glb"),
	preload("res://art3d/classic64_pack/Nature/bush_05.glb"),
]
const ROCKS: Array[PackedScene] = [
	preload("res://art3d/classic64_pack/Rocks/rock_handpainted_1.glb"),
	preload("res://art3d/classic64_pack/Rocks/rock_handpainted_2.glb"),
	preload("res://art3d/classic64_pack/Rocks/rock_handpainted_3.glb"),
]
const FARM_SIGN := preload("res://art3d/extras/AloneInTheDusk/Sign_01.glb")
const BROKEN_LAMP := preload("res://art3d/extras/AloneInTheDusk/Lamp_broken_01.glb")
const FALLEN_TRUNK := preload("res://art3d/extras/AloneInTheDusk/Trunk_01.glb")
const WITCH_PINE := preload("res://art3d/extras/LOFI_DREAD/pine_tall.glb")
const EFFIGY := preload("res://art3d/extras/LOFI_DREAD/stick_effigy.glb")

func _ready() -> void:
	_make_path()
	_place_forest()
	_place_downloaded_dressing()
	_add_color_seep()

func _place_downloaded_dressing() -> void:
	# Siluetas nuevas a los lados del sendero; el centro queda libre para jugar.
	var sign := FARM_SIGN.instantiate()
	sign.name = "SeñalGranjaAbandonada"
	sign.position = Vector3(-5.2, 0.0, -1.8)
	sign.rotation.y = 0.22
	sign.scale = Vector3.ONE * 0.82
	add_child(sign)
	var lamp := BROKEN_LAMP.instantiate()
	lamp.name = "FarolRotoDelSendero"
	lamp.position = Vector3(5.4, 0.0, 2.7)
	lamp.rotation.y = -0.3
	lamp.scale = Vector3.ONE * 0.78
	add_child(lamp)
	var trunk := FALLEN_TRUNK.instantiate()
	trunk.name = "TroncoCaidoFueraDelPaso"
	trunk.position = Vector3(-8.5, 0.0, 3.1)
	trunk.rotation.y = 0.6
	trunk.scale = Vector3.ONE * 0.85
	add_child(trunk)
	var pine := WITCH_PINE.instantiate()
	pine.name = "PinoAislado"
	pine.position = Vector3(6.8, 0.0, -6.8)
	pine.scale = Vector3.ONE * 0.72
	add_child(pine)
	var effigy := EFFIGY.instantiate()
	effigy.name = "EspantapajarosDeRamas"
	effigy.position = Vector3(-4.3, 0.0, 3.0)
	effigy.rotation.y = -0.45
	effigy.scale = Vector3.ONE * 0.82
	add_child(effigy)

func _make_path() -> void:
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color(0.14, 0.105, 0.085)
	dirt.roughness = 1.0
	var points := [Vector2(-11.0, -3.5), Vector2(-7.0, -2.6), Vector2(-3.0, -1.3), Vector2(1.0, 0.1), Vector2(4.2, 2.0), Vector2(9.5, 4.4)]
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var direction := finish - start
		var path := CSGBox3D.new()
		path.name = "SenderoDeTierra_%02d" % i
		path.size = Vector3(direction.length() + 0.55, 0.035, 2.8)
		path.position = Vector3((start.x + finish.x) * 0.5, 0.012, (start.y + finish.y) * 0.5)
		path.rotation.y = -atan2(direction.y, direction.x)
		path.use_collision = false
		path.material = dirt
		add_child(path)

func _place_forest() -> void:
	# Un anillo de árboles despeja el sendero y corta la vista hacia la granja.
	var placements := [
		[0, Vector3(-10.8, 0.0, -6.1), 0.15, 1.0],
		[2, Vector3(-10.9, 0.0, 2.0), 0.4, 0.78],
		[1, Vector3(-7.2, 0.0, 6.1), 0.8, 1.0],
		[4, Vector3(-6.0, 0.0, -6.2), 0.3, 0.9],
		[3, Vector3(-3.2, 0.0, 5.7), 0.2, 0.92],
		[0, Vector3(-1.8, 0.0, -6.2), 0.5, 1.0],
		[1, Vector3(2.2, 0.0, 6.0), 0.3, 0.95],
		[2, Vector3(4.2, 0.0, -6.0), 0.7, 0.82],
		[4, Vector3(8.0, 0.0, 6.0), 0.1, 0.9],
		[0, Vector3(10.9, 0.0, -5.8), 0.7, 1.0],
		[3, Vector3(11.7, 0.0, -1.3), 0.4, 0.82],
		[1, Vector3(-10.9, 0.0, 6.1), 0.6, 0.9],
	]
	for item in placements:
		_add_tree(TREES[item[0]], item[1], item[2], item[3])

	for pos in [Vector3(-4.4, 0.0, -5.1), Vector3(0.0, 0.0, 5.2), Vector3(6.4, 0.0, -5.0)]:
		_add_tree(SMALL_TREE, pos, 0.0, 1.5)

	var bush_positions := [
		Vector3(-11.1, 0.15, -4.8), Vector3(-9.0, 0.15, -6.1), Vector3(-8.9, 0.15, 4.8),
		Vector3(-6.0, 0.15, 6.0), Vector3(-3.0, 0.15, -5.8), Vector3(-1.8, 0.15, 6.1),
		Vector3(3.1, 0.15, 6.0), Vector3(5.8, 0.15, -5.8), Vector3(8.4, 0.15, 5.8),
		Vector3(10.8, 0.15, -4.3), Vector3(11.2, 0.15, 1.0), Vector3(-10.3, 0.15, 1.6),
	]
	for i in bush_positions.size():
		var bush: Node3D = BUSHES[i % BUSHES.size()].instantiate()
		bush.name = "Matorral_%02d" % i
		bush.position = bush_positions[i]
		bush.rotation.y = float(i) * 0.83
		bush.scale = Vector3.ONE * (0.8 + float(i % 3) * 0.16)
		add_child(bush)

	var rock_positions := [Vector3(-8.2, 0.25, -3.8), Vector3(-2.3, 0.2, 5.6), Vector3(4.2, 0.2, -5.1), Vector3(10.4, 0.25, 5.8)]
	for i in rock_positions.size():
		var rock: Node3D = ROCKS[i % ROCKS.size()].instantiate()
		rock.name = "PiedraBosque_%02d" % i
		rock.position = rock_positions[i]
		rock.rotation.y = float(i) * 1.17
		rock.scale = Vector3.ONE * (0.48 + float(i % 2) * 0.12)
		add_child(rock)

func _add_tree(scene: PackedScene, pos: Vector3, yaw: float, scale_factor: float) -> void:
	var tree: Node3D = scene.instantiate()
	tree.position = pos
	tree.rotation.y = yaw
	tree.scale = Vector3.ONE * scale_factor
	add_child(tree)

func _add_color_seep() -> void:
	var stain := OmniLight3D.new()
	stain.name = "ResplandorDelColor"
	stain.position = Vector3(0.4, 0.38, 1.0)
	stain.light_color = Color(0.60, 0.23, 0.78)
	stain.light_energy = 0.7
	stain.omni_range = 7.5
	stain.shadow_enabled = false
	add_child(stain)

	var spore_material := StandardMaterial3D.new()
	spore_material.albedo_color = Color(0.55, 0.27, 0.72, 0.86)
	spore_material.emission_enabled = true
	spore_material.emission = Color(0.54, 0.15, 0.82)
	spore_material.emission_energy_multiplier = 1.4
	for i in 5:
		var spore := CSGSphere3D.new()
		spore.name = "EsporaColor_%02d" % i
		spore.radius = 0.07 + float(i % 2) * 0.035
		spore.position = Vector3(-1.0 + float(i) * 0.58, 0.15 + float(i % 3) * 0.18, 1.15 + sin(float(i)) * 0.5)
		spore.use_collision = false
		spore.material = spore_material
		add_child(spore)
