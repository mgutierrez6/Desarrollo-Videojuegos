extends Node

var punto_spawn: String = "default"
var caja_dialogo: CanvasLayer = null
var inventario_ui: CanvasLayer = null

# true si hay alguna pantalla abierta que tenga que frenar al jugador
func jugador_bloqueado() -> bool:
	if is_instance_valid(caja_dialogo) and (caja_dialogo.visible_dialogo or caja_dialogo.eligiendo):
		return true
	if is_instance_valid(inventario_ui) and inventario_ui.abierto:
		return true
	if InspeccionUI.abierto or KeypadUi.abierto:
		return true
	return false
