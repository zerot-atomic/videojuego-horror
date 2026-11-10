extends RefCounted
# ============================================================
# Arregla en tiempo de ejecucion los materiales de los .glb:
#  1) Blender no exporto las texturas de muchos materiales, asi que los
#     .material externos quedaron VACIOS (todo blanco) y Godot los conserva
#     (materials/keep_on_reimport = true). Aqui se les vuelve a poner su textura.
#  2) glTF asume metallic = 1 cuando el material no lo indica: en Godot se ve
#     como metal blanco/negro. Se baja a 0 si no hay textura de metalico.
# Se llama desde Zone3D despues de armar el cuarto y el jugador.
# ============================================================

const TEXTURES := {
	"res://art3d/classic64_pack/Color_OffWhite.material": "res://art3d/classic64_pack/Misc/Colors/Color_OffWhite.png",
	"res://art3d/classic64_pack/Doors/Door_Shed_A.material": "res://art3d/classic64_pack/Doors/Materials/door_shed_a.png",
	"res://art3d/classic64_pack/Doors/Door_Shed_B.material": "res://art3d/classic64_pack/Doors/Materials/door_shed_b.png",
	"res://art3d/classic64_pack/Doors/color_silver.material": "res://art3d/classic64_pack/Misc/Colors/color_silver.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_1.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_1.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_2.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_2.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_3.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_3.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_4.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_4.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_5.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_5.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_6.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_6.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_7.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_7.png",
	"res://art3d/classic64_pack/Food/Drink_Can_Soda_8.material": "res://art3d/classic64_pack/Food/Materials/drink_can_soda_8.png",
	"res://art3d/classic64_pack/Food/Food_Baking_Sugar.material": "res://art3d/classic64_pack/Food/Materials/food_baking_sugar.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_1.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_1.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_10.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_10.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_2.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_2.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_3.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_3.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_4.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_4.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_5.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_5.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_6.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_6.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_7.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_7.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_8.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_8.png",
	"res://art3d/classic64_pack/Food/Food_Canned_Soup_9.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_9.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_1.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_1.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_2.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_2.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_3.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_3.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_4.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_4.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_5.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_5.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_6.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_6.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_7.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_7.png",
	"res://art3d/classic64_pack/Food/Food_Cereal_8.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_8.png",
	"res://art3d/classic64_pack/Food/Food_Pet.material": "res://art3d/classic64_pack/Food/Materials/food_pet.png",
	"res://art3d/classic64_pack/Food/Food_Pet_2.material": "res://art3d/classic64_pack/Food/Materials/food_pet_2.png",
	"res://art3d/classic64_pack/Food/food_baking_flour.material": "res://art3d/classic64_pack/Food/Materials/food_baking_flour.png",
	"res://art3d/classic64_pack/Food/food_snack_chips_1.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_1.png",
	"res://art3d/classic64_pack/Food/food_snack_chips_2.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_2.png",
	"res://art3d/classic64_pack/Food/food_snack_chips_3.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_3.png",
	"res://art3d/classic64_pack/Food/food_snack_chips_4.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_4.png",
	"res://art3d/classic64_pack/Food_Baking_Sugar.material": "res://art3d/classic64_pack/Food/Materials/food_baking_sugar.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_1.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_1.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_2.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_2.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_3.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_3.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_5.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_5.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_6.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_6.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_7.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_7.png",
	"res://art3d/classic64_pack/Food_Canned_Soup_8.material": "res://art3d/classic64_pack/Food/Materials/food_canned_soup_8.png",
	"res://art3d/classic64_pack/Food_Cereal_1.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_1.png",
	"res://art3d/classic64_pack/Food_Cereal_2.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_2.png",
	"res://art3d/classic64_pack/Food_Cereal_3.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_3.png",
	"res://art3d/classic64_pack/Food_Cereal_4.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_4.png",
	"res://art3d/classic64_pack/Food_Cereal_5.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_5.png",
	"res://art3d/classic64_pack/Food_Cereal_6.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_6.png",
	"res://art3d/classic64_pack/Food_Cereal_7.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_7.png",
	"res://art3d/classic64_pack/Food_Cereal_8.material": "res://art3d/classic64_pack/Food/Materials/food_cereal_8.png",
	"res://art3d/classic64_pack/Food_Pet.material": "res://art3d/classic64_pack/Food/Materials/food_pet.png",
	"res://art3d/classic64_pack/Food_Pet_2.material": "res://art3d/classic64_pack/Food/Materials/food_pet_2.png",
	"res://art3d/classic64_pack/Nature/nature_sapling.material": "res://art3d/classic64_pack/Nature/Materials/branches_leaves.png",
	"res://art3d/classic64_pack/Nature/nature_tree_trunk.material": "res://art3d/classic64_pack/Nature/Materials/tree_trunk.png",
	"res://art3d/classic64_pack/Panels/panel_electric.material": "res://art3d/classic64_pack/Panels/Materials/panel_electric.png",
	"res://art3d/classic64_pack/Papers/Envolope_Redacted.material": "res://art3d/classic64_pack/Papers/Materials/envolope_redacted.png",
	"res://art3d/classic64_pack/Rocks/rock_1.material": "res://art3d/classic64_pack/Rocks/Materials/rock1.png",
	"res://art3d/classic64_pack/Rocks/rock_2.material": "res://art3d/classic64_pack/Rocks/Materials/rock2.png",
	"res://art3d/classic64_pack/Rocks/rock_3.material": "res://art3d/classic64_pack/Rocks/Materials/rock3.png",
	"res://art3d/classic64_pack/Rocks/rock_4.material": "res://art3d/classic64_pack/Rocks/Materials/rock4.png",
	"res://art3d/classic64_pack/Rocks/rock_5.material": "res://art3d/classic64_pack/Rocks/Materials/rock5.png",
	"res://art3d/classic64_pack/Shelves/Color_OffWhite.material": "res://art3d/classic64_pack/Misc/Colors/Color_OffWhite.png",
	"res://art3d/classic64_pack/Shelves/metal_rack_stackable.material": "res://art3d/classic64_pack/Shelves/Materials/metal_rack_stackable.png",
	"res://art3d/classic64_pack/Signs/signpost_silver.material": "res://art3d/classic64_pack/Signs/Materials/signpost_silver.png",
	"res://art3d/classic64_pack/Units/Color_BlackDirty.material": "res://art3d/classic64_pack/Misc/Colors/color_blackdirty.png",
	"res://art3d/classic64_pack/Units/Color_BlackSmooth.material": "res://art3d/classic64_pack/Misc/Colors/color_blacksmooth.png",
	"res://art3d/classic64_pack/Units/Color_OffWhite.material": "res://art3d/classic64_pack/Misc/Colors/Color_OffWhite.png",
	"res://art3d/classic64_pack/Units/Color_Silver.material": "res://art3d/classic64_pack/Misc/Colors/color_silver.png",
	"res://art3d/classic64_pack/Units/Metal_Aluminium.material": "res://art3d/classic64_pack/Metal/Materials/metal_aluminium.png",
	"res://art3d/classic64_pack/Units/Metal_Smooth.material": "res://art3d/classic64_pack/Metal/Materials/metal_smooth.png",
	"res://art3d/classic64_pack/Units/Panel_Tempature_Control.material": "res://art3d/classic64_pack/Panels/Materials/panel_tempature_control.png",
	"res://art3d/classic64_pack/Units/generator.material": "res://art3d/classic64_pack/Units/Materials/generator.png",
	"res://art3d/classic64_pack/Walls/wood_plank_2.material": "res://art3d/classic64_pack/Wood/Materials/wood_plank_2.png",
	"res://art3d/classic64_pack/Windows/Window_Boarded.material": "res://art3d/classic64_pack/Windows/Materials/window_boarded.png",
	"res://art3d/classic64_pack/Windows/window_frame_green.material": "res://art3d/classic64_pack/Windows/Materials/window_shutter_green.png",
	"res://art3d/classic64_pack/Windows/window_modern.material": "res://art3d/classic64_pack/Windows/Materials/window_modern.png",
	"res://art3d/classic64_pack/Windows/window_shutter_black.material": "res://art3d/classic64_pack/Windows/Materials/window_shutter_black.png",
	"res://art3d/classic64_pack/Windows/window_shutter_green.material": "res://art3d/classic64_pack/Windows/Materials/window_shutter_green.png",
	"res://art3d/classic64_pack/Windows/window_shutter_red.material": "res://art3d/classic64_pack/Windows/Materials/window_shutter_red.png",
	"res://art3d/classic64_pack/food_baking_flour.material": "res://art3d/classic64_pack/Food/Materials/food_baking_flour.png",
	"res://art3d/classic64_pack/food_snack_chips_1.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_1.png",
	"res://art3d/classic64_pack/food_snack_chips_2.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_2.png",
	"res://art3d/classic64_pack/food_snack_chips_3.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_3.png",
	"res://art3d/classic64_pack/food_snack_chips_4.material": "res://art3d/classic64_pack/Food/Materials/food_snack_chips_4.png",
	"res://art3d/horror_pack/HorrorPackFBX/DoorTexture.material": "res://art3d/horror_pack/textures/OldDoorPhoto.png",
	"res://art3d/horror_pack/HorrorPackFBX/FloorTexture.material": "res://art3d/horror_pack/textures/WoodGround.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/Material.material": "res://art3d/horror_pack/textures/kNIFE.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/RoofTexture.material": "res://art3d/horror_pack/textures/weathered_brown_planks_diff_1k.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/Rusttexture.material": "res://art3d/horror_pack/textures/RustTexture.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/WallPaint.material": "res://art3d/horror_pack/textures/WallPaint.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/WallPaint_002.material": "res://art3d/horror_pack/textures/WallPaint.jpg",
	"res://art3d/horror_pack/HorrorPackFBX/bedMaterial.material": "res://art3d/horror_pack/textures/bed.jpg"
}

# Los modelos de roca traen el nombre del material glTF embebido en el GLB,
# no la ruta de los .material externos. Resolvemos por nombre para esos casos.
const NAMED_TEXTURES := {
	"rock_1": "res://art3d/classic64_pack/Rocks/Materials/rock1.png",
	"rock_2": "res://art3d/classic64_pack/Rocks/Materials/rock2.png",
	"rock_3": "res://art3d/classic64_pack/Rocks/Materials/rock3.png",
	"rock_4": "res://art3d/classic64_pack/Rocks/Materials/rock4.png",
	"rock_5": "res://art3d/classic64_pack/Rocks/Materials/rock5.png",
	"nature_tree_trunk": "res://art3d/classic64_pack/Nature/Materials/tree_trunk.png",
	"nature_sapling": "res://art3d/classic64_pack/Nature/Materials/branches_leaves.png",
	"generator": "res://art3d/classic64_pack/Units/Materials/generator.png",
	"window_frame_green": "res://art3d/classic64_pack/Windows/Materials/window_shutter_green.png",
	"Window_Boarded": "res://art3d/classic64_pack/Windows/Materials/window_boarded.png",
	"wood_plank_2": "res://art3d/classic64_pack/Wood/Materials/wood_plank_2.png",
	"FloorTexture": "res://art3d/horror_pack/textures/WoodGround.jpg",
	"WallPaint": "res://art3d/horror_pack/textures/WallPaint.jpg",
	"WallPaint.002": "res://art3d/horror_pack/textures/WallPaint.jpg",
	"WoodNightStandTexture": "res://art3d/horror_pack/HorrorPackFBX/NightStand_1_Image.png",
	"bedMaterial": "res://art3d/horror_pack/textures/bed.jpg",
	"RoofTexture": "res://art3d/horror_pack/textures/weathered_brown_planks_diff_1k.jpg",
}

static func fix(root: Node) -> void:
	_walk(root)

static func _walk(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var mesh = node.mesh
		for i in range(mesh.get_surface_count()):
			_fix_material(mesh.surface_get_material(i))
	for child in node.get_children():
		_walk(child)

static func _fix_material(mat) -> void:
	if mat == null or not (mat is StandardMaterial3D):
		return
	if mat.has_meta("mat_fixed"):
		return
	mat.set_meta("mat_fixed", true)
	var path: String = mat.resource_path
	var texture_path: String = TEXTURES.get(path, NAMED_TEXTURES.get(mat.resource_name, ""))
	if mat.albedo_texture == null and texture_path != "":
		var tex = load(texture_path)
		if tex != null:
			mat.albedo_texture = tex
	if mat.metallic_texture == null and mat.metallic > 0.95:
		mat.metallic = 0.0
	if mat.roughness_texture == null and mat.roughness > 0.95:
		mat.roughness = 0.85
