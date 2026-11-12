extends Area2D

@export var codigo := "4821"
@export var flag := "compu_abierta"
@export_multiline var registro := "RUTINAS DEL PUEBLO\n\nLuis: perder la llave de la tienda (cada mañana).\nEmma: preguntar si dormiste bien (cada mañana).\nVicky: llenar el balde (todo el día).\n\nEstado: estable.\nAnomalías registradas: 1."

var _usando := false

func hay_algo_para_hacer() -> bool:
	return not GameManager.flags.get(flag, false)

func interactuar() -> void:
	if _usando:
		return
	_usando = true
	if not GameManager.flags.get(flag, false):
		var ok = await KeypadUi.abrir(codigo)
		if ok:
			GameManager.flags[flag] = true
			InspeccionUI.mostrar(null, registro)
	else:
		InspeccionUI.mostrar(null, registro)
	_usando = false
