extends Node3D
# ============================================================
# Arena de pruebas aislada para el monstruo Wrapper3D. No es parte
# del juego real: es solo para poder correr ESTA escena sola
# (F6 en Godot, o el botón de "reproducir escena") y ver/ajustar la
# persecución sin tener que recorrer toda la granja.
#
# Al cabo de un par de segundos, el Wrapper "emerge" (grito) y
# empieza a perseguir al jugador. Camina para ver que te alcanza;
# corre (Shift) para ver que sí lo puedes dejar atrás; méanle contra
# la pared/columna del medio para ver el tropiezo.
# ============================================================

@onready var player = $Player3D
@onready var wrapper = $Wrapper3D

func _ready():
	await get_tree().create_timer(1.5).timeout
	wrapper.start_chase(player)
