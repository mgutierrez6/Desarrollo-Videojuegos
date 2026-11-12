extends Area2D

signal inspeccionado

@export var imagen: Texture2D
@export_multiline var texto: String = ""
@export var flag_visto: String = ""    # ej: "foto_vista", "nota_vista"
@export_group("Brillo")
@export var brillo := true
var _t := 0.0
var visto := false

func _process(delta: float) -> void:
	_t += delta
	if brillo and not visto:
		var v := 1.05 + 0.2 * sin(_t * 3.0)
		modulate = Color(v, v, v, 1.0)

func interactuar() -> void:
	if InspeccionUI.abierto:
		return
	InspeccionUI.mostrar(imagen, texto)
	if flag_visto != "":
		visto = true
		GameManager.flags[flag_visto] = true
	inspeccionado.emit()

func hay_algo_para_hacer() -> bool:
	return flag_visto == "" or not GameManager.flags.get(flag_visto, false)
