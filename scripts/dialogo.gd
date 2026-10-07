extends Area2D
@export_multiline var texto: Array[String] = ["..."]
func interactuar() -> void:
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(texto)
