extends Area2D

var texto: Array = ["No se puede pasar...", "Tal vez alguien sabe de una forma"]

func interactuar() -> void:
	if Global.caja_dialogo != null:
		Global.caja_dialogo.iniciar_dialogo(texto)
