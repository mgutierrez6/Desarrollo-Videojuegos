extends Area2D

signal desbloqueado

@export var item_requerido: String = "Llave"
@export var consumir_item: bool = true
@export var flag: String = "puerta1_abierta"
@export var txt_sin_item: Array = ["Está cerrado."]
@export_multiline var txt_item_incorrecto: String = "Eso no sirve acá."
@export_multiline var txt_exito: String = "¡Funcionó!"
@export_multiline var txt_ya_resuelto: String = "Ya está resuelto."

func _decir(t):
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(t)

func interactuar() -> void:
	if GameManager.flags.get(flag, false):
		_decir([txt_ya_resuelto])
		return
	var sel = GameManager.item_seleccionado
	if sel == "":
		_decir(txt_sin_item)
	elif sel != item_requerido:
		_decir([txt_item_incorrecto])
	else:
		if consumir_item:
			GameManager.remover_item(sel)
		GameManager.flags[flag] = true
		_decir([txt_exito])
		desbloqueado.emit()  # conectá esta señal a la puerta/colisión/etc.
