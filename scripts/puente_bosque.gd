extends Node2D

func _ready():
	if Global.punto_spawn == "desde_main":
		# Reemplaza "$Jugador" por la ruta exacta de tu nodo de personaje en esta escena
		$Jugador.global_position = $SpawnMain.global_position
