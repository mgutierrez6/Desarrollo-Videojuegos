extends Node2D

@onready var horas_sprite = $Hs
@onready var minutos_sprite = $Min

@export var hora_congelada := 4        # 1 a 12
@export var minuto_congelado := 20

var _usando := false

func _process(_delta):
	var hora: int
	var minuto: int
	var segundo := 0
	if GameManager.flags.get("reloj_congelado", false):
		hora = hora_congelada
		minuto = minuto_congelado
	else:
		var tiempo = Time.get_time_dict_from_system()
		hora = tiempo["hour"]
		minuto = tiempo["minute"]
		segundo = tiempo["second"]
	minutos_sprite.rotation = ((minuto + segundo / 60.0) / 60.0) * TAU
	horas_sprite.rotation = (((hora % 12) + minuto / 60.0) / 12.0) * TAU

func _codigo() -> String:
	return "%02d%02d" % [hora_congelada, minuto_congelado]

func hay_algo_para_hacer() -> bool:
	return GameManager.flags.get("reloj_congelado", false) and not GameManager.flags.get("reloj_resuelto", false)

func _decir(lineas: Array) -> void:
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(lineas)
		await Global.caja_dialogo.dialogo_terminado

func interactuar() -> void:
	if _usando:
		return
	_usando = true
	await _interactuar()
	_usando = false

func _interactuar() -> void:
	if not GameManager.flags.get("reloj_congelado", false):
		var t = Time.get_time_dict_from_system()
		await _decir(["Son las %02d:%02d." % [t["hour"], t["minute"]]])
		return
	if GameManager.flags.get("reloj_resuelto", false):
		return
	if not GameManager.flags.get("reloj_leido", false):
		GameManager.flags["reloj_leido"] = true
		await _decir(["El reloj está detenido.", "Marca las %d y %02d." % [hora_congelada, minuto_congelado], "En la base hay un panel con teclado."])
		return
	var ok = await KeypadUi.abrir(_codigo())
	if ok:
		GameManager.flags["reloj_resuelto"] = true
