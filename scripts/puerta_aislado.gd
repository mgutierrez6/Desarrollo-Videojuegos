extends Area2D
# Puerta del aislado en un solo nodo: voz -> teclado -> pasar.

signal desbloqueado

@export var codigo := "314"
@export var flag_abierta := "puerta_aislado_abierta"
@export var flag_voz := "voz_puerta"
@export var flag_requerido := "golpe_oido"       # vacío = no exige haber oído los golpes

@export_group("Textos")
@export var voz: Array[String] = [
	"...¿Hay alguien? Shh. No hables.",
	"Me escuchan cuando se habla. Cuando se golpea, no.",
	"Escuchá. Siempre es el mismo ritmo."
]
@export_multiline var txt_silencio := "Una puerta cerrada, con un teclado al lado. Nadie responde."
@export_multiline var txt_exito := "Se oye un clic."
@export var objetivo_voz := "Escuchá el ritmo de los golpes"
@export var objetivo_abierta := "Entrar a la casa"

@export_group("Destino")
@export_file("*.tscn", "*.scn") var escena := "res://escenas/casaAislada.tscn"
@export var punto_spawn := "desde_afuera"

var _usando := false

func hay_algo_para_hacer() -> bool:
	return true

func _decir(lineas: Array, voz: String = "aislado") -> void:
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(lineas, voz)
		await Global.caja_dialogo.dialogo_terminado

func interactuar() -> void:
	if _usando:
		return
	_usando = true
	await _interactuar()
	_usando = false

func _interactuar() -> void:
	# 4) ya abierta: pasar
	if GameManager.flags.get(flag_abierta, false):
		Global.punto_spawn = punto_spawn
		Transicion.ir_a(escena)
		return
	# 1) antes de oír los golpes, la puerta no responde
	if flag_requerido != "" and not GameManager.flags.get(flag_requerido, false):
		await _decir([txt_silencio], "pueblo")
		return
	# 2) primera vez: la voz
	if not GameManager.flags.get(flag_voz, false):
		GameManager.flags[flag_voz] = true
		await _decir(voz, "aislado")
		if objetivo_voz != "":
			GameManager.set_objetivo(objetivo_voz, "aislado")
		return
	# 3) después: el teclado
	var ok = await KeypadUi.abrir(codigo)
	if ok:
		GameManager.flags[flag_abierta] = true
		if objetivo_abierta != "":
			GameManager.set_objetivo(objetivo_abierta, "aislado")
		desbloqueado.emit()
		await _decir([txt_exito], "pueblo")
