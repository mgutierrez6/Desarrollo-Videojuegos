extends Area2D

var texto: Array = ["Este es un cartel de prueba."]

func interactuar() -> void:
	if Global.caja_dialogo != null:
		Global.caja_dialogo.iniciar_dialogo(texto)
	else:
		print("Error: Global.caja_dialogo es null. ¿Olvidaste agregar CajaDialogo al mapa?")
