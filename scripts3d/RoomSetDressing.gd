extends Node3D

const HOUSE_TABLE := preload("res://art3d/psx_house_pack/props/table.glb")
const HOUSE_CHAIR := preload("res://art3d/psx_house_pack/props/chair.glb")
const HOUSE_BOOKS := preload("res://art3d/psx_house_pack/props/book4.glb")
const HOUSE_PAINTING := preload("res://art3d/props_extra/house/painting.glb")
const ATTIC_TEDDY := preload("res://art3d/props_extra/attic/teddybear.glb")
const ATTIC_CHESS := preload("res://art3d/props_extra/attic/chessboard.glb")
const ATTIC_MIRROR := preload("res://art3d/props_extra/attic/mirror.glb")
const ATTIC_CASE := preload("res://art3d/props_extra/attic/case_low.glb")
const BARN_PALLET := preload("res://art3d/props_extra/barn/pallet.glb")
const BARN_BUCKET := preload("res://art3d/props_extra/barn/bucket2.glb")
const BARN_BOX := preload("res://art3d/props_extra/barn/box3.glb")
const FARM_ROCK := preload("res://art3d/extras/AloneInTheDusk/rocks_02.glb")
const FARM_LAMP := preload("res://art3d/extras/AloneInTheDusk/lamp_01.glb")
const NATURE_GRASS := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_grass_01.glb")
const NATURE_FERN := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_fern_01.glb")
const NATURE_FLOWERS := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_flowers_01.glb")
const NATURE_BUSH := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_bush_01.glb")
const NATURE_ROCKS := preload("res://art3d/extras/Nature_Terrain/glTF/mdvl_nature_rock_mossy_01.glb")

func _ready() -> void:
	match get_parent().name:
		"Room_casa_principal": _dress_house()
		"Room_atico": _dress_attic()
		"Room_establo": _dress_barn()
		"Room_campo_cultivo": _dress_field()
		"Room_bosque": _dress_forest()
		"Room_camino_entrada": _dress_road()
		"Room_pozo": _dress_well()
		"Room_crater_meteorito": _dress_crater()
		"Room_laberinto": _dress_maze()

func _dress_house() -> void:
	# Recibidor suroeste: consola y retrato familiar contra la pared sur.
	# El centro queda libre para entrar y pasar al salón.
	_add_prop(HOUSE_TABLE, "ConsolaRecibidor", Vector3(-9.3, 0.0, 5.55), PI, 0.82, Vector3(1.25, 0.78, 0.62))
	_add_prop(HOUSE_PAINTING, "RetratoFamiliarRecibidor", Vector3(-9.3, 1.72, 6.72), PI * 0.5, 0.68)
	# Luz cálida local de lámpara para que la sala se lea como vivienda sin aclarar el exterior.
	var lamp_light := OmniLight3D.new()
	lamp_light.name = "LuzCalidaSala"
	lamp_light.position = Vector3(-8.7, 1.25, -3.7)
	lamp_light.light_color = Color(1.0, 0.68, 0.42)
	lamp_light.light_energy = 0.5
	lamp_light.omni_range = 5.2
	lamp_light.omni_attenuation = 1.5
	lamp_light.shadow_enabled = false
	add_child(lamp_light)

func _dress_attic() -> void:
	# Rincones con objetos personales y cajas, sin cubrir la salida de la trampilla.
	_add_prop(ATTIC_CASE, "BaulAntiguo", Vector3(-7.0, 0.0, 4.8), 0.45, 0.95)
	_add_prop(ATTIC_MIRROR, "EspejoGuardado", Vector3(-10.2, 0.0, 2.2), 0.0, 0.75)
	_add_prop(ATTIC_TEDDY, "OsoDePelucheOlvidado", Vector3(10.0, 0.72, 0.8), -0.3, 0.72)
	_add_prop(ATTIC_CHESS, "AjedrezIncompleto", Vector3(-6.3, 0.82, -4.5), 0.15, 0.62)
	_add_prop(HOUSE_BOOKS, "LibrosPolvorientosAtico", Vector3(6.4, 0.08, -5.7), 0.25, 0.85)
	_add_box("TelaCaidaAtico", Vector3(1.0, 0.06, 0.75), Vector3(8.4, 0.04, 4.6), Color(0.26, 0.21, 0.18))

func _dress_barn() -> void:
	# Pacas, zona de alimento y herramientas hacen legible el uso del establo.
	var straw := _mat(Color(0.42, 0.34, 0.16))
	for i in 5:
		var bale := CSGBox3D.new()
		bale.name = "PacaDeHeno_%02d" % i
		bale.size = Vector3(1.25, 0.78, 0.82)
		bale.position = Vector3(-9.0 + float(i % 2) * 0.28, 0.39 + float(i / 2) * 0.78, -4.8 + float(i % 3) * 1.05)
		bale.material = straw
		bale.use_collision = false
		add_child(bale)
	_add_prop(BARN_PALLET, "TarimaDeAlimento", Vector3(7.8, 0.02, 4.9), 0.2, 0.8)
	_add_prop(BARN_BOX, "CajaDeForraje", Vector3(7.5, 0.05, 4.7), 0.0, 0.8)
	_add_prop(BARN_BUCKET, "CuboDeAguaSucio", Vector3(4.9, 0.0, 4.9), 0.25, 0.8)
	# Pesebre de madera improvisado contra la pared, dejando libre la ruta de patrulla.
	_add_box("PesebreMadera", Vector3(2.8, 0.72, 0.75), Vector3(-1.5, 0.38, 5.4), Color(0.23, 0.15, 0.09))
	_add_box("AguaTurbiaPesebre", Vector3(2.5, 0.04, 0.48), Vector3(-1.5, 0.77, 5.4), Color(0.22, 0.26, 0.21, 0.85))
	_add_box("ParedPesebreFrontal", Vector3(2.8, 0.35, 0.12), Vector3(-1.5, 0.55, 5.82), Color(0.29, 0.20, 0.12))

func _dress_field() -> void:
	# CAMPO CULTIVO: tierra agotada, cultivos amarillentos/marchitos, niebla densa y ocre
	# Hierba base: tono enfermizo, más densa cerca de los bordes
	var field_grass_mat := _mat(Color(0.22, 0.18, 0.08))
	field_grass_mat.roughness = 1.0
	_add_grass(360, 10.8, 6.0, 0.18, 0.35, 142)
	# Capa de "hierba muerta" - más baja y amarillenta
	var dead_grass_mat := _mat(Color(0.35, 0.28, 0.12))
	dead_grass_mat.roughness = 1.0
	var mm_dead := MultiMesh.new()
	mm_dead.transform_format = MultiMesh.TRANSFORM_3D
	mm_dead.use_colors = true
	mm_dead.mesh = _grass_mesh()
	mm_dead.instance_count = 180
	var rng_dead := RandomNumberGenerator.new()
	rng_dead.seed = 143
	for i in 180:
		var at := Vector3(rng_dead.randf_range(-10.8, 10.8), -0.015, rng_dead.randf_range(-6.0, 6.0))
		if absf(at.x) < 2.2:
			at.x += 3.2 if at.x >= 0.0 else -3.2
		var height := rng_dead.randf_range(0.06, 0.14)
		var basis := Basis(Vector3.UP, rng_dead.randf_range(0.0, TAU)).scaled(Vector3(height, height, height))
		mm_dead.set_instance_transform(i, Transform3D(basis, at))
		mm_dead.set_instance_color(i, Color(rng_dead.randf_range(0.7, 0.95), rng_dead.randf_range(0.55, 0.75), rng_dead.randf_range(0.2, 0.35), 1.0))
	var dead_grass_node := MultiMeshInstance3D.new()
	dead_grass_node.name = "HierbaMarchita"
	dead_grass_node.multimesh = mm_dead
	dead_grass_node.material_override = dead_grass_mat
	add_child(dead_grass_node)
	_scatter_nature(NATURE_GRASS, 16, 10.6, 5.8, 0.55, 0.85, 142, true)
	# Flores marchitas - tonos apagados, casi grises
	var wilted_flower_mat := _mat(Color(0.42, 0.35, 0.22))
	_scatter_nature(NATURE_FLOWERS, 6, 10.2, 5.6, 0.45, 0.7, 509, true)
	# Hileras de cultivo enfermo - MAÍZ/TALLOS amarillentos con hojas caídas
	var crop_mat := _mat(Color(0.38, 0.28, 0.10))
	for row in 5:
		var x := -9.0 + float(row) * 4.0
		if absf(x) < 2.5:
			continue
		for stalk in 6:
			var z := -5.0 + float(stalk) * 2.2 + float(row % 2) * 0.4
			if x > 2.4 and z < -4.5:
				continue
			var stem := CSGCylinder3D.new()
			stem.name = "TalloEnfermo_%02d_%02d" % [row, stalk]
			stem.radius = 0.045
			stem.height = 0.95 + float((row + stalk) % 3) * 0.15
			stem.position = Vector3(x, stem.height * 0.5, z)
			stem.material = crop_mat
			stem.use_collision = false
			add_child(stem)
			# Hojas colgantes, amarillentas
			var leaf := CSGBox3D.new()
			leaf.name = "HojaMarchita_%02d_%02d" % [row, stalk]
			leaf.size = Vector3(0.52, 0.04, 0.1)
			leaf.position = Vector3(x + (0.28 if stalk % 2 == 0 else -0.28), stem.height * 0.52, z)
			leaf.rotation.z = -0.35 if stalk % 2 == 0 else 0.32
			leaf.rotation.x = 0.15 if stalk % 2 == 0 else -0.12
			leaf.material = _mat(Color(0.45, 0.35, 0.15))
			leaf.use_collision = false
			add_child(leaf)
	# Montículos de tierra removida (efecto de cultivo fallido)
	var mound_mat := _mat(Color(0.25, 0.20, 0.14))
	var rng_mounds := RandomNumberGenerator.new()
	rng_mounds.seed = 143
	for i in 8:
		var angle := TAU * float(i) / 8.0 + 0.3
		var dist := 4.0 + float(i % 3) * 1.5
		var mound := CSGBox3D.new()
		mound.name = "MonticuloTierra_%02d" % i
		mound.size = Vector3(1.8, 0.25, 1.2)
		mound.position = Vector3(cos(angle) * dist, 0.08, sin(angle) * dist)
		mound.rotation.y = rng_mounds.randf_range(0.0, TAU)
		mound.material = mound_mat
		mound.use_collision = false
		add_child(mound)
	# Espantapájaros caído - landmark visual
	var scarecrow_mat := _mat(Color(0.28, 0.22, 0.15))
	var scarecrow_post := CSGBox3D.new()
	scarecrow_post.name = "PosteEspantapajaros"
	scarecrow_post.size = Vector3(0.12, 1.8, 0.12)
	scarecrow_post.position = Vector3(-6.5, 0.9, 2.1)
	scarecrow_post.material = scarecrow_mat
	scarecrow_post.use_collision = false
	add_child(scarecrow_post)
	var scarecrow_arms := CSGBox3D.new()
	scarecrow_arms.name = "BrazosEspantapajaros"
	scarecrow_arms.size = Vector3(1.6, 0.1, 0.1)
	scarecrow_arms.position = Vector3(-6.5, 1.5, 2.1)
	scarecrow_arms.rotation.z = -0.15
	scarecrow_arms.material = scarecrow_mat
	scarecrow_arms.use_collision = false
	add_child(scarecrow_arms)
	# Trozos de tela vieja en los brazos
	for j in 3:
		var rag := CSGBox3D.new()
		rag.name = "TrapoEspantapajaros_%02d" % j
		rag.size = Vector3(0.4, 0.02, 0.06)
		rag.position = Vector3(-6.5 + (j - 1) * 0.5, 1.5 + float(j) * 0.05, 2.1 + rng_dead.randf_range(-0.1, 0.1))
		rag.rotation.y = rng_dead.randf_range(-0.3, 0.3)
		rag.material = _mat(Color(0.35, 0.28, 0.22))
		rag.use_collision = false
		add_child(rag)

func _dress_forest() -> void:
	_add_grass(260, 12.0, 8.0, 0.16, 0.28, 822)
	_scatter_nature(NATURE_GRASS, 28, 12.0, 8.0, 0.65, 1.05, 822, true)
	_scatter_nature(NATURE_FERN, 9, 12.0, 8.0, 0.72, 1.0, 823, true)
	_scatter_nature(NATURE_BUSH, 5, 12.0, 8.0, 0.68, 0.9, 824, true)
	_add_prop(FARM_ROCK, "PiedrasJuntoAlSendero", Vector3(-5.0, 0.0, 2.2), 0.3, 0.55)
	_add_prop(FARM_LAMP, "FarolEnterrado", Vector3(9.0, 0.0, -1.8), -0.5, 0.72)

func _dress_road() -> void:
	# CAMINO ENTRADA: camino de tierra seca, niebla baja, farol cálido, árboles frondosos
	_add_grass(380, 22.0, 20.0, 0.12, 0.28, 119)
	_scatter_nature(NATURE_GRASS, 24, 22.0, 20.0, 0.55, 0.88, 119, true)
	_scatter_nature(NATURE_FERN, 6, 22.0, 18.0, 0.55, 0.85, 120, true)
	# Árboles de entrada - marcan el camino hacia la casa
	_add_prop(FARM_LAMP, "FarolEntradaGranja", Vector3(10.8, 0.0, 2.8), PI, 0.82)
	# Hitos visuales: poste de luz roto, piedras sueltas del camino
	var path_stone_mat := _mat(Color(0.35, 0.32, 0.28))
	var rng_path := RandomNumberGenerator.new()
	rng_path.seed = 119
	for i in 8:
		var angle := TAU * float(i) / 8.0 + 0.4
		var dist := 8.5 + float(i % 3) * 1.2
		var stone := CSGBox3D.new()
		stone.name = "PiedraCamino_%02d" % i
		stone.size = Vector3(0.45, 0.12, 0.38)
		stone.position = Vector3(cos(angle) * dist, -0.02, sin(angle) * dist)
		stone.rotation.y = rng_path.randf_range(0.0, TAU)
		stone.material = path_stone_mat
		stone.use_collision = false
		add_child(stone)
	# Charcos residuales reflectantes (efecto visual sutil)
	var puddle_mat := _mat(Color(0.08, 0.06, 0.12))
	puddle_mat.roughness = 0.15
	puddle_mat.metallic = 0.6
	for pos in [Vector3(-4.2, -0.01, 1.8), Vector3(2.1, -0.01, -0.8), Vector3(7.5, -0.01, 3.2), Vector3(-8.8, -0.01, -2.1)]:
		var puddle := CSGBox3D.new()
		puddle.name = "CharcoCamino"
		puddle.size = Vector3(1.2, 0.015, 0.8)
		puddle.position = pos
		puddle.material = puddle_mat
		puddle.use_collision = false
		add_child(puddle)

func _dress_well() -> void:
	# Brocal bajo de piedra alrededor del pozo; el centro se deja libre para la interacción.
	var stone := _mat(Color(0.23, 0.22, 0.22))
	for i in 10:
		var angle := TAU * float(i) / 10.0
		var block := CSGBox3D.new()
		block.name = "BrocalPiedra_%02d" % i
		block.size = Vector3(1.0, 0.48, 0.62)
		block.position = Vector3(cos(angle) * 1.55, 0.18, sin(angle) * 1.55)
		block.rotation.y = -angle
		block.material = stone
		block.use_collision = false
		add_child(block)
	_add_grass(300, 16.0, 14.0, 0.10, 0.22, 530)
	_scatter_nature(NATURE_GRASS, 18, 16.0, 14.0, 0.52, 0.78, 530, true)
	_scatter_nature(NATURE_ROCKS, 5, 6.0, 6.0, 0.45, 0.62, 531, false)
	var stain := OmniLight3D.new()
	stain.name = "LuzFiltradaDelPozo"
	stain.position = Vector3(0.0, 0.55, 0.0)
	stain.light_color = Color(0.42, 0.16, 0.62)
	stain.light_energy = 0.55
	stain.omni_range = 5.0
	stain.shadow_enabled = false
	add_child(stain)

func _dress_crater() -> void:
	# CRÁTER METEORITO: tonos alienígenas (púrpura/verde enfermo), cristales extraños, niebla densa y baja
	# Sin hierba normal - solo "musgo alien" y cristales
	var alien_moss_mat := _mat(Color(0.12, 0.22, 0.10))
	alien_moss_mat.roughness = 1.0
	var mm_moss := MultiMesh.new()
	mm_moss.transform_format = MultiMesh.TRANSFORM_3D
	mm_moss.use_colors = true
	mm_moss.mesh = _grass_mesh()
	mm_moss.instance_count = 120
	var rng_moss := RandomNumberGenerator.new()
	rng_moss.seed = 790
	for i in 120:
		var at := Vector3(rng_moss.randf_range(-18.0, 18.0), -0.01, rng_moss.randf_range(-16.0, 16.0))
		# Evitar el centro exacto donde está el meteorito
		if Vector2(at.x, at.z).length() < 3.5:
			continue
		var height := rng_moss.randf_range(0.08, 0.22)
		var basis := Basis(Vector3.UP, rng_moss.randf_range(0.0, TAU)).scaled(Vector3(height, height, height))
		mm_moss.set_instance_transform(i, Transform3D(basis, at))
		mm_moss.set_instance_color(i, Color(rng_moss.randf_range(0.3, 0.6), rng_moss.randf_range(0.5, 0.85), rng_moss.randf_range(0.2, 0.45), 1.0))
	var moss_node := MultiMeshInstance3D.new()
	moss_node.name = "MusgoAlien"
	moss_node.multimesh = mm_moss
	moss_node.material_override = alien_moss_mat
	add_child(moss_node)
	# Rocas del cráter - más oscuras, con vetas extrañas
	var crater_rock_mat := _mat(Color(0.15, 0.10, 0.18))
	_scatter_nature(NATURE_ROCKS, 14, 17.0, 14.0, 0.5, 0.8, 791, true)
	# Cristales púrpuras creciendo de las rocas - landmark principal
	var crystal_mat := _mat(Color(0.42, 0.12, 0.58))
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.55, 0.08, 0.72)
	crystal_mat.emission_energy_multiplier = 1.2
	crystal_mat.roughness = 0.2
	crystal_mat.metallic = 0.3
	for i in 18:
		var angle := TAU * float(i) / 18.0 + rng_moss.randf_range(-0.15, 0.15)
		var dist := 3.8 + float(i % 4) * 1.8 + rng_moss.randf_range(-0.4, 0.4)
		var height := 0.8 + float(i % 3) * 0.4 + rng_moss.randf_range(-0.1, 0.15)
		var crystal := CSGBox3D.new()
		crystal.name = "CristalAlien_%02d" % i
		crystal.size = Vector3(0.18, height, 0.14)
		crystal.position = Vector3(cos(angle) * dist, height * 0.5, sin(angle) * dist)
		crystal.rotation.y = rng_moss.randf_range(0.0, TAU)
		crystal.rotation.x = rng_moss.randf_range(-0.12, 0.12)
		crystal.rotation.z = rng_moss.randf_range(-0.08, 0.08)
		crystal.material = crystal_mat
		crystal.use_collision = false
		add_child(crystal)
	# Segundo anillo de cristales más pequeños
	var small_crystal_mat := _mat(Color(0.35, 0.08, 0.52))
	small_crystal_mat.emission_enabled = true
	small_crystal_mat.emission = Color(0.48, 0.05, 0.65)
	small_crystal_mat.emission_energy_multiplier = 0.8
	small_crystal_mat.roughness = 0.3
	for i in 12:
		var angle := TAU * float(i) / 12.0 + 0.13 + rng_moss.randf_range(-0.1, 0.1)
		var dist := 7.5 + float(i % 3) * 1.2 + rng_moss.randf_range(-0.3, 0.3)
		var height := 0.4 + float(i % 2) * 0.25 + rng_moss.randf_range(-0.05, 0.1)
		var crystal := CSGBox3D.new()
		crystal.name = "CristalPequeño_%02d" % i
		crystal.size = Vector3(0.12, height, 0.09)
		crystal.position = Vector3(cos(angle) * dist, height * 0.5, sin(angle) * dist)
		crystal.rotation.y = rng_moss.randf_range(0.0, TAU)
		crystal.rotation.x = rng_moss.randf_range(-0.08, 0.08)
		crystal.rotation.z = rng_moss.randf_range(-0.05, 0.05)
		crystal.material = small_crystal_mat
		crystal.use_collision = false
		add_child(crystal)
	# "Sangre" del color - charcos iridiscentes en el suelo
	var iridescent_mat := _mat(Color(0.18, 0.05, 0.28))
	iridescent_mat.roughness = 0.08
	iridescent_mat.metallic = 0.85
	iridescent_mat.emission_enabled = true
	iridescent_mat.emission = Color(0.25, 0.04, 0.38)
	iridescent_mat.emission_energy_multiplier = 0.5
	for pos in [Vector3(-2.1, -0.005, 1.8), Vector3(3.4, -0.005, -2.2), Vector3(-5.8, -0.005, -1.5), Vector3(1.2, -0.005, 4.1), Vector3(-7.2, -0.005, 3.8), Vector3(6.5, -0.005, 0.9)]:
		var pool := CSGBox3D.new()
		pool.name = "CharcoIridiscente"
		pool.size = Vector3(1.8, 0.02, 1.3)
		pool.position = pos
		pool.rotation.y = rng_moss.randf_range(0.0, TAU)
		pool.material = iridescent_mat
		pool.use_collision = false
		add_child(pool)
	# Árboles muertos retorcidos alrededor del cráter
	var dead_tree_mat := _mat(Color(0.10, 0.08, 0.12))
	for i in 6:
		var angle := TAU * float(i) / 6.0 + 0.52
		var dist := 13.5 + rng_moss.randf_range(-0.8, 0.8)
		var trunk := CSGBox3D.new()
		trunk.name = "ArbolMuerto_%02d" % i
		trunk.size = Vector3(0.25, 2.8, 0.25)
		trunk.position = Vector3(cos(angle) * dist, 1.4, sin(angle) * dist)
		trunk.rotation.y = angle + PI * 0.5
		trunk.rotation.x = rng_moss.randf_range(-0.15, 0.15)
		trunk.rotation.z = rng_moss.randf_range(-0.12, 0.12)
		trunk.material = dead_tree_mat
		trunk.use_collision = false
		add_child(trunk)
		# Ramas retorcidas
		for b in 3:
			var branch := CSGBox3D.new()
			branch.name = "RamaMuerta_%02d_%02d" % [i, b]
			branch.size = Vector3(0.8, 0.07, 0.07)
			branch.position = Vector3(cos(angle) * dist, 2.2 + float(b) * 0.3, sin(angle) * dist)
			branch.rotation.y = angle + PI * 0.5 + rng_moss.randf_range(-0.5, 0.5)
			branch.rotation.x = rng_moss.randf_range(-0.4, 0.4)
			branch.rotation.z = rng_moss.randf_range(-0.3, 0.3)
			branch.material = dead_tree_mat
			branch.use_collision = false
			add_child(branch)
	# Niebla local densa extra (se suma a la del WorldEnvironment)
	var fog_light := OmniLight3D.new()
	fog_light.name = "LuzNieblaCrater"
	fog_light.position = Vector3(0.0, 0.8, 0.0)
	fog_light.light_color = Color(0.28, 0.12, 0.42)
	fog_light.light_energy = 0.35
	fog_light.omni_range = 28.0
	fog_light.shadow_enabled = false
	add_child(fog_light)
	# Partículas flotantes sutiles (usando luces muy pequeñas)
	for i in 8:
		var spark := OmniLight3D.new()
		spark.name = "ParticulaColor_%02d" % i
		spark.position = Vector3(rng_moss.randf_range(-12.0, 12.0), rng_moss.randf_range(0.5, 2.5), rng_moss.randf_range(-12.0, 12.0))
		spark.light_color = Color(0.55, 0.15, 0.75)
		spark.light_energy = 0.18
		spark.omni_range = 2.5
		spark.shadow_enabled = false
		add_child(spark)

func _dress_maze() -> void:
	# Señales de que el bosque contaminó el laberinto; luces pequeñas, sin cambiar las rutas.
	var rune_mat := _mat(Color(0.22, 0.08, 0.34))
	rune_mat.emission_enabled = true
	rune_mat.emission = Color(0.31, 0.06, 0.48)
	rune_mat.emission_energy_multiplier = 0.9
	var rune_mesh := _make_rune_mesh()
	for i in 12:
		var rune := MeshInstance3D.new()
		rune.name = "MarcaDelColor_%02d" % i
		rune.mesh = rune_mesh
		rune.material_override = rune_mat
		rune.scale = Vector3(0.12, 0.62 + float(i % 3) * 0.16, 0.06)
		rune.position = Vector3(-29.55 if i % 2 == 0 else 29.55, 0.65 + float(i % 2) * 0.6, -25.0 + float(i) * 4.2)
		add_child(rune)

func _make_rune_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := 0.5
	var hy := 0.5
	var hz := 0.5
	var verts := [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz),
		Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz),
	]
	var faces := [
		[0,1,2, 0,2,3], [4,5,6, 4,6,7], [0,1,5, 0,5,4],
		[2,3,7, 2,7,6], [1,2,6, 1,6,5], [0,3,7, 0,7,4],
	]
	for f in faces:
		var n_vec: Vector3 = (verts[f[1]] - verts[f[0]]).cross(verts[f[2]] - verts[f[0]]).normalized()
		for i in f:
			st.set_normal(n_vec); st.add_vertex(verts[i])
	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _add_prop(scene: PackedScene, prop_name: String, at: Vector3, yaw: float, scale_factor: float, collider_size: Vector3 = Vector3.ZERO) -> Node3D:
	var prop := scene.instantiate() as Node3D
	prop.name = prop_name
	prop.position = at
	prop.rotation.y = yaw
	prop.scale = Vector3.ONE * scale_factor
	add_child(prop)
	if collider_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = prop_name + "Collision"
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = collider_size
		collision.shape = box
		collision.position.y = collider_size.y * 0.5
		body.add_child(collision)
		prop.add_child(body)
	return prop

func _add_box(box_name: String, size: Vector3, at: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = box_name
	box.size = size
	box.position = at
	box.material = _mat(color)
	box.use_collision = false
	add_child(box)
	return box

func _scatter_nature(scene: PackedScene, count: int, half_x: float, half_z: float, min_scale: float, max_scale: float, seed_value: int, keep_path_clear: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var at := Vector3(rng.randf_range(-half_x, half_x), -0.02, rng.randf_range(-half_z, half_z))
		if keep_path_clear and (get_parent().name == "Room_campo_cultivo" or get_parent().name == "Room_camino_entrada") and absf(at.x) < 3.0:
			continue
		if keep_path_clear and get_parent().name == "Room_camino_entrada" and Vector2(at.x - 5.656, at.z + 0.581).length() < 3.0:
			continue
		if keep_path_clear and get_parent().name == "Room_pozo" and Vector2(at.x, at.z).length() < 3.2:
			continue
		var asset_name := scene.resource_path.get_file().get_basename()
		_add_prop(scene, "%s_%02d" % [asset_name, i], at, rng.randf_range(0.0, TAU), rng.randf_range(min_scale, max_scale))

func _add_grass(count: int, half_x: float, half_z: float, min_h: float, max_h: float, seed_value: int) -> void:
	var blade_mesh := _grass_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade_mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var at := Vector3(rng.randf_range(-half_x, half_x), -0.02, rng.randf_range(-half_z, half_z))
		# Leave a narrow, irregular walking lane through the field and wooded path.
		if (get_parent().name == "Room_campo_cultivo" or get_parent().name == "Room_camino_entrada") and absf(at.x) < 2.2:
			at.x += 3.2 if at.x >= 0.0 else -3.2
		if get_parent().name == "Room_camino_entrada":
			var doorway_offset := Vector2(at.x - 5.656, at.z + 0.581)
			if doorway_offset.length() < 3.0:
				var push := doorway_offset.normalized() * (3.1 - doorway_offset.length())
				at.x += push.x
				at.z += push.y
		var height := rng.randf_range(min_h, max_h)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(height, height, height))
		mm.set_instance_transform(i, Transform3D(basis, at))
		mm.set_instance_color(i, Color(rng.randf_range(0.72, 1.08), rng.randf_range(0.72, 1.08), rng.randf_range(0.68, 0.9), 1.0))
	var grass := MultiMeshInstance3D.new()
	grass.name = "HierbaBaja"
	grass.multimesh = mm
	add_child(grass)

func _grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color := Color(0.34, 0.42, 0.18)
	# Tres hojas triangulares cruzadas por mata, con caras visibles a ambos lados.
	for angle in [0.0, PI / 3.0, 2.0 * PI / 3.0]:
		var side := Vector3(cos(angle), 0.0, sin(angle)) * 0.075
		var tip := Vector3(cos(angle + 0.35), 0.23, sin(angle + 0.35))
		st.set_color(color); st.add_vertex(-side)
		st.set_color(color); st.add_vertex(side)
		st.set_color(color); st.add_vertex(tip)
	st.generate_normals()
	var mesh := st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
