extends Area2D

signal desbloqueado

@export var codigo: String = "1234"
@export var flag: String = "keypad1_resuelto"
@export_multiline var txt_exito: String = "Se oye un clic."
@export_multiline var txt_ya_resuelto: String = "Ya está abierto."

var _usando := false

func _decir(t: String) -> void:
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo([t])

func interactuar() -> void:
	if GameManager.flags.get(flag, false):
		_decir(txt_ya_resuelto)
		return
	if _usando:
		return
	_usando = true
	var ok = await KeypadUi.abrir(codigo)
	_usando = false
	if ok:
		GameManager.flags[flag] = true
		_decir(txt_exito)
		desbloqueado.emit()
