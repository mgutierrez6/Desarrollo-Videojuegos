extends Area2D
# Cada vez que las investigás pasa algo más; a la tercera ceden.

@export var textos: Array[String] = [
	"Una pila de piedras. Parece que está ahí hace mucho.",
	"Del otro lado se oyen golpes...",
	"Las piedras tiemblan."
]
@export var nodo_piedras: NodePath
@export var flag_contador := "piedras_investigadas"
@export var flag_abierta := "piedras_abiertas"
@export var audio: NodePath

var _usando := false

func hay_algo_para_hacer() -> bool:
	return not GameManager.flags.get(flag_abierta, false)

func interactuar() -> void:
	if _usando or GameManager.flags.get(flag_abierta, false):
		return
	_usando = true
	var n: int = mini(int(GameManager.flags.get(flag_contador, 0)) + 1, textos.size())
	GameManager.flags[flag_contador] = n
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo([textos[n - 1]])
		await Global.caja_dialogo.dialogo_terminado
	if n >= textos.size():
		await _ceder()
	_usando = false

func _ceder() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var t := create_tween()
		for i in range(8):
			t.tween_property(cam, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.04)
		t.tween_property(cam, "offset", Vector2.ZERO, 0.05)
		await t.finished
	GameManager.flags[flag_abierta] = true
	var sonido := get_node_or_null(audio)
	if sonido:
		sonido.play()
	var p := get_node_or_null(nodo_piedras)
	if p:
		var fade := create_tween()
		fade.tween_property(p, "modulate:a", 0.0, 0.6)
		await fade.finished
		p.queue_free()
