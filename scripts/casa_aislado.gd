extends Node2D

@export var probar_finales := false

func _ready() -> void:
	$Jugador.global_position = $SpawnEntrada.global_position

	var agujero := get_node_or_null("Agujero")
	if agujero:
		agujero.desbloqueado.connect(func(): GameManager.agregar_item("Llave de la caja"))

	if probar_finales:
		GameManager.agregar_item("LinternaPrendida")
		GameManager.agregar_item("Palo magnetico")
