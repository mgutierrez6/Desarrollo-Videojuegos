extends Area2D

@export var flags_requeridos: Array[String] = []   # ej: ["foto_vista", "nota_vista"]
@export var texto_normal: Array[String] = ["..."]
@export var texto_con_pista: Array[String] = ["..."]

func interactuar() -> void:
	if not Global.caja_dialogo:
		return
	if _cumple_requisitos():
		Global.caja_dialogo.iniciar_dialogo(texto_con_pista)
	else:
		Global.caja_dialogo.iniciar_dialogo(texto_normal)

func _cumple_requisitos() -> bool:
	if flags_requeridos.is_empty():
		return false
	for f in flags_requeridos:
		if not GameManager.flags.get(f, false):
			return false
	return true
