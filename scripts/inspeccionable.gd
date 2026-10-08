extends Area2D

signal inspeccionado

@export var imagen: Texture2D
@export_multiline var texto: String = ""
@export var flag_visto: String = ""    # ej: "foto_vista", "nota_vista"

func interactuar() -> void:
	if InspeccionUI.abierto:
		return
	InspeccionUI.mostrar(imagen, texto)
	if flag_visto != "":
		GameManager.flags[flag_visto] = true
	inspeccionado.emit()
