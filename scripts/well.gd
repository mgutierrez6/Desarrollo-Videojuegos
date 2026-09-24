extends Area2D

var interacciones: int = 0

func interactuar() -> void:
	if not Global.caja_dialogo:
		return

	if interacciones == 0:
		Global.caja_dialogo.iniciar_dialogo(["Un pozo de agua viejo y oscuro, sin balde atado."])
	elif interacciones == 1:
		Global.caja_dialogo.iniciar_dialogo(["Miras más de cerca... parece haber algo en el fondo."])
	else:
		Global.caja_dialogo.iniciar_dialogo(["Parece haber algo en el fondo, pero no hay balde."])

	interacciones += 1 # Incrementamos para la próxima vez que vuelva a tocar 'E'
