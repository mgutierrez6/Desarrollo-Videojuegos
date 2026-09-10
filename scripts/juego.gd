extends Node2D

func _ready():
	if Global.punto_spawn == "desde_puente":
		# Reemplaza "$Jugador" por la ruta exacta de tu nodo de personaje en esta escena
		$Jugador.global_position = $SpawnPuente.global_position
