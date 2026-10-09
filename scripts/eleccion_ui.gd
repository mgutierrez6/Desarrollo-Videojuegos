extends Node

var abierto: bool:
	get:
		return Global.caja_dialogo != null and Global.caja_dialogo.eligiendo

func elegir(pregunta: String, opciones: Array) -> int:
	if Global.caja_dialogo == null:
		return -1
	return await Global.caja_dialogo.elegir(pregunta, opciones)
