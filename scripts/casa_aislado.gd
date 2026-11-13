extends Node2D

@export var probar_finales := true


func _ready() -> void:
	Global.punto_spawn = "desde_afuera"
	if Global.punto_spawn == "desde_afuera":
		$Jugador.global_position = $SpawnEntrada.global_position
		$Agujero.desbloqueado.connect(func(): GameManager.agregar_item("Llave de la caja"))
	else:
		$Jugador.global_position = $SpawnEntrada.global_position

	if probar_finales:
		GameManager.agregar_item("LinternaPrendida") #agregamos el palo y la linterna para acelerar
		GameManager.agregar_item("Palo magnetico")
