extends Area2D

@export_file("*.tscn", "*.scn") var escena: String
@export var punto_spawn: String = "default"
@export var pregunta: String = ""            
@export var opcion_si := "Entrar"
@export var opcion_no := "Quedarme"

var _usando := false

func interactuar() -> void:
	if _usando or escena == "":
		return
	_usando = true
	if pregunta != "":
		var i = await EleccionUi.elegir(pregunta, [opcion_si, opcion_no])
		if i != 0:
			_usando = false
			return
	Global.punto_spawn = punto_spawn
	get_tree().change_scene_to_file(escena)
