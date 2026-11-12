extends Node2D

func _ready() -> void:
	if Global.punto_spawn == "desde_afuera":
		$Jugador.global_position = $SpawnEntrada.global_position
		$Agujero.desbloqueado.connect(func(): GameManager.agregar_item("Llave de la caja"))
	else:
		$Jugador.global_position = $SpawnEntrada.global_position
