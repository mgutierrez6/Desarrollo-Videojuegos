extends Area2D

var texto: Array = ["Este es un cartel de prueba."]

func interactuar() -> void:
	if Global.caja_dialogo != null:
		Global.caja_dialogo.iniciar_dialogo(texto)
