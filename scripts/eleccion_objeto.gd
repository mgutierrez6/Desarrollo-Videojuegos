extends Area2D

signal elegida(indice: int)

@export_multiline var pregunta: String = "¿Qué hacés?"
@export var opciones: Array[String] = ["Entrar", "No entrar"]
# Texto que se dice después de cada opción (mismo orden que las opciones)
@export var respuestas: Array[String] = ["", ""]
@export var flag_decision: String = "decision1"
@export var una_sola_vez: bool = true

var _usando := false

func interactuar() -> void:
	if _usando or EleccionUi.abierto:
		return
	if una_sola_vez and _ya_decidido():
		if Global.caja_dialogo:
			Global.caja_dialogo.iniciar_dialogo(["Ya tomaste esa decisión."])
		return
	_usando = true
	var i = await EleccionUi.elegir(pregunta, opciones)
	_usando = false
	if i < 0:
		return
	# guarda un flag por opción: "decision1_0", "decision1_1", etc.
	GameManager.flags[flag_decision + "_" + str(i)] = true
	if i < respuestas.size() and respuestas[i] != "" and Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo([respuestas[i]])
	elegida.emit(i)

func _ya_decidido() -> bool:
	for i in range(opciones.size()):
		if GameManager.flags.get(flag_decision + "_" + str(i), false):
			return true
	return false
