extends Area2D

signal etapa_ejecutada(etapa: EtapaDialogo)

@export var etapas: Array[EtapaDialogo] = []

var _ocupado := false

func interactuar() -> void:
	if _ocupado or not Global.caja_dialogo or Global.jugador_bloqueado():
		return
	for e in etapas:
		if e != null and _cumple(e):
			await _ejecutar(e)
			return

func _cumple(e: EtapaDialogo) -> bool:
	for f in e.flags_requeridos:
		if not GameManager.flags.get(f, false):
			return false
	for f in e.flags_prohibidos:
		if GameManager.flags.get(f, false):
			return false
	for it in e.items_requeridos:
		if not GameManager.tiene_item(it):
			return false
	return true

func _ejecutar(e: EtapaDialogo) -> void:
	_ocupado = true
	if not e.texto.is_empty():
		Global.caja_dialogo.iniciar_dialogo(e.texto)
		await Global.caja_dialogo.dialogo_terminado
	for f in e.flags_a_activar:
		GameManager.flags[f] = true
	for it in e.items_a_quitar:
		GameManager.remover_item(it)
	if e.item_a_dar != "":
		GameManager.agregar_item(e.item_a_dar)
		var nombre = GameManager.datos_items.get(e.item_a_dar, {}).get("nombre", e.item_a_dar)
		Global.caja_dialogo.iniciar_dialogo(["Recibiste: " + nombre])
	if e.objetivo_nuevo != "":
		GameManager.set_objetivo(e.objetivo_nuevo)
	_ocupado = false
	etapa_ejecutada.emit(e)
