extends Area3D
class_name Interactable3D
# ============================================================
# Versión 3D de Interactable.gd.
#
# Cambio clave frente al original: ya NO dibuja su propio ícono/label
# en pantalla (eso ahora lo puede seguir haciendo el aviso inferior de
# GameManager.show_message, como ya pasa al examinar una pista). Aquí
# solo se marca el punto interactuable en el mundo 3D real.
#
# Colócalo a mano en el editor, dentro de la escena de cada cuarto,
# encima o pegado al objeto 3D que representa (un cajón del Classic 64
# Pack, la mesa del HorrorPackFBX, etc.). Ya no necesitas coordenadas
# x,y a mano en GameManager.CLUES: su posición ES la posición real.
#
# Requiere agregar esta función a GameManager.gd (ver nota aparte):
#   func get_clue_data(zone_id: String, clue_id: String) -> Dictionary
# ============================================================

@export var clue_id: String = ""
@export var display_name: String = ""   # de momento solo referencia tuya; no se dibuja
@export var is_item: bool = false

func is_locked() -> bool:
	var data = GameManager.get_clue_data(GameManager.current_zone_id, clue_id)
	var req = data.get("requires_item", "") if data else ""
	return req != "" and not GameManager.inventory.get(req, false)

func interact():
	if is_locked():
		var data = GameManager.get_clue_data(GameManager.current_zone_id, clue_id)
		GameManager.show_message(
			data.get("locked_message", "Está cerrado."),
			GameManager.resolve_icon("", false, true),
			"Bloqueado"
		)
		return
	GameManager.examine_clue(clue_id)
