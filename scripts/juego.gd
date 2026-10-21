extends Node2D

func _ready():
	if Global.punto_spawn == "desde_puente":
		$Jugador.global_position = $SpawnPuente.global_position
	if Global.punto_spawn == "desde_casa1":
		$Jugador.global_position = $SpawnCasa1.global_position
		

	$fuenteGate.desbloqueado.connect(func(): GameManager.agregar_item("Llave de la tienda"))

	## Piedras: desaparecen cuando Ramiro tiene su momento
	#_actualizar_piedras()
	#$Ramiro.etapa_ejecutada.connect(func(_e): _actualizar_piedras())

func _actualizar_piedras() -> void:
	if GameManager.flags.get("piedras_abiertas", false):
		var p = get_node_or_null("Piedras")
		if p:
			p.queue_free()

# Ayuda para probar: F10 muestra los flags en la consola
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		print(GameManager.flags)
