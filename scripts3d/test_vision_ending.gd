extends Node

@onready var game_manager = get_node("/root/GameManager")
@onready var transition = get_node("/root/ScreenDoorTransition")

var current_zone = ""
var test_results = []

func _ready():
	print("=== Starting Vision/Ending/SaveLoad Tests ===")
	await get_tree().process_frame

	await test_establo_vision()
	await test_atico_vision()
	await test_bosque_vision()
	await test_pozo_decision()
	await test_endings()
	await test_save_load()

	print("\n=== ALL TESTS COMPLETE ===")
	for r in test_results:
		print(r)

	get_tree().quit()

func test_establo_vision():
	current_zone = "establo"
	game_manager.change_zone("establo", "Spawn")
	await get_tree().process_frame
	await get_tree().process_frame

	if game_manager.visions_seen.has("padre"):
		test_results.append("FAIL: padre vision should not be seen initially")
		return
	if game_manager.inventory.has("llave_oxidada"):
		test_results.append("FAIL: should not have llave_oxidada initially")
		return
	print("  Initial state OK: no padre vision, no llave_oxidada")

	var clue = get_tree().current_scene.find_child("Clue_ganado_establo")
	if clue:
		clue.interact()
		await get_tree().process_frame
		if game_manager.visions_seen.has("padre"):
			test_results.append("FAIL: vision should not trigger without key")
			return
		print("  Clue locked without llave_oxidada: OK")

	game_manager.inventory.append("llave_oxidada")
	game_manager.save_game()
	if clue:
		clue.interact()
		await get_tree().process_frame
		await get_tree().process_frame

		if game_manager.pending_vision == "padre":
			print("  Vision triggered: padre vision pending")
			test_results.append("PASS: Establo ganado_establo triggers padre vision with key")
		else:
			test_results.append("FAIL: Establo ganado_establo did not trigger padre vision")
	else:
		test_results.append("FAIL: Clue_ganado_establo not found in scene")

func test_atico_vision():
	current_zone = "atico"
	game_manager.change_zone("atico", "Spawn")
	await get_tree().process_frame
	await get_tree().process_frame

	if game_manager.visions_seen.has("madre"):
		test_results.append("FAIL: madre vision should not be seen initially")
		return
	print("  Initial state OK: no madre vision")

	var clue = get_tree().current_scene.find_child("Clue_diario_madre")
	if clue:
		clue.interact()
		await get_tree().process_frame
		await get_tree().process_frame

		if game_manager.pending_vision == "madre":
			print("  Vision triggered: madre vision pending")
			test_results.append("PASS: Atico diario_madre triggers madre vision")
		else:
			test_results.append("FAIL: Atico diario_madre did not trigger madre vision")
	else:
		test_results.append("FAIL: Clue_diario_madre not found in scene")

func test_bosque_vision():
	current_zone = "bosque"
	game_manager.change_zone("bosque", "Spawn")
	await get_tree().process_frame
	await get_tree().process_frame

	if game_manager.visions_seen.has("hijo"):
		test_results.append("FAIL: hijo vision should not be seen initially")
		return
	print("  Initial state OK: no hijo vision")

	var clue = get_tree().current_scene.find_child("Clue_zapato_hijo")
	if clue:
		clue.interact()
		await get_tree().process_frame
		await get_tree().process_frame

		if game_manager.pending_vision == "hijo":
			print("  Vision triggered: hijo vision pending")
			test_results.append("PASS: Bosque zapato_hijo triggers hijo vision")
		else:
			test_results.append("FAIL: Bosque zapato_hijo did not trigger hijo vision")
	else:
		test_results.append("FAIL: Clue_zapato_hijo not found in scene")

func test_pozo_decision():
	current_zone = "pozo"
	game_manager.change_zone("pozo", "Spawn")
	await get_tree().process_frame
	await get_tree().process_frame

	var clue_retirarse = get_tree().current_scene.find_child("Clue_retirarse")
	if clue_retirarse:
		clue_retirarse.interact()
		await get_tree().process_frame
		await get_tree().process_frame

		if game_manager.pending_vision == "ending" and game_manager.pending_ending_type == "retreat":
			print("  Retreat ending triggered")
			test_results.append("PASS: Pozo Clue_retirarse triggers retreat ending")
		else:
			test_results.append("FAIL: Pozo Clue_retirarse did not trigger retreat ending")
	else:
		test_results.append("FAIL: Clue_retirarse not found in scene")

	var clue_descender = get_tree().current_scene.find_child("Clue_descender")
	if clue_descender:
		clue_descender.interact()
		await get_tree().process_frame
		if game_manager.pending_vision == "ending":
			test_results.append("FAIL: descender should be locked without manivela")
			return
		print("  Descender locked without manivela_pozo: OK")

		game_manager.inventory.append("manivela_pozo")
		clue_descender.interact()
		await get_tree().process_frame
		await get_tree().process_frame

		if game_manager.pending_vision == "ending" and game_manager.pending_ending_type == "decision":
			print("  Decision ending triggered")
			test_results.append("PASS: Pozo Clue_descender triggers decision ending with manivela")
		else:
			test_results.append("FAIL: Pozo Clue_descender did not trigger decision ending")
	else:
		test_results.append("FAIL: Clue_descender not found in scene")

func test_endings():
	game_manager.corruption_time_elapsed = 100
	game_manager.visions_seen.clear()
	game_manager.visions_seen.append("padre")
	game_manager.visions_seen.append("madre")
	game_manager.visions_seen.append("hijo")
	game_manager.difficulty = "NORMAL"

	game_manager.decide_ending()
	if game_manager.pending_ending_type == "good":
		test_results.append("PASS: Good ending with low corruption and all visions")
	else:
		test_results.append("FAIL: Should get good ending")

	game_manager.corruption_time_elapsed = 1000
	game_manager.decide_ending()
	if game_manager.pending_ending_type == "bad":
		test_results.append("PASS: Bad ending with high corruption")
	else:
		test_results.append("FAIL: Should get bad ending")

	game_manager.corruption_time_elapsed = 100
	game_manager.visions_seen.clear()
	game_manager.visions_seen.append("padre")
	game_manager.decide_ending()
	if game_manager.pending_ending_type == "bad":
		test_results.append("PASS: Bad ending with missing visions")
	else:
		test_results.append("FAIL: Should get bad ending")

func test_save_load():
	var pass = true
	game_manager.inventory.clear()
	game_manager.inventory.append("test_item")
	game_manager.visions_seen.clear()
	game_manager.visions_seen.append("padre")
	game_manager.flags["test_flag"] = true
	game_manager.corruption_time_elapsed = 42.5
	game_manager.current_zone = "test_zone"
	game_manager.pending_spawn_marker = "test_spawn"
	game_manager.difficulty = "HARD"

	game_manager.save_game()
	print("  Game saved")

	var new_gm = GameManager.new()
	get_tree().root.add_child(new_gm)
	new_gm.load_game()
	await get_tree().process_frame

	if not new_gm.inventory.has("test_item"):
		test_results.append("FAIL: Inventory not persisted")
		pass = false
	if not new_gm.visions_seen.has("padre"):
		test_results.append("FAIL: Visions not persisted")
		pass = false
	if not new_gm.flags["test_flag"]:
		test_results.append("FAIL: Flags not persisted")
		pass = false
	if abs(new_gm.corruption_time_elapsed - 42.5) >= 0.01:
		test_results.append("FAIL: Corruption time not persisted")
		pass = false
	if new_gm.current_zone != "test_zone":
		test_results.append("FAIL: Current zone not persisted")
		pass = false
	if new_gm.pending_spawn_marker != "test_spawn":
		test_results.append("FAIL: Spawn marker not persisted")
		pass = false
	if new_gm.difficulty != "HARD":
		test_results.append("FAIL: Difficulty not persisted")
		pass = false

	if pass:
		test_results.append("PASS: Save/Load persists all critical state")
	new_gm.queue_free()