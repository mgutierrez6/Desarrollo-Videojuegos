extends Node
# Acto 3: entra el Sistema, elegís a quién escuchar y hay que llegar al reloj
# antes de que el reinicio borre el pueblo. No hay game over: cambia el final.

@export var reloj: Node2D                       # opcional: si queda vacío busca un nodo "clock"
@export var segundos := 50.0                    # tiempo hasta que el frente llega al reloj
@export var distancia_inicial := 260.0          # qué tan atrás empieza el frente (fuera de pantalla)
@export var sonido_pulso: AudioStream           # opcional: latido o golpe que se acelera
@export var escena_final := "res://escenas/final.tscn"

const COLOR_OLA := {
	"sistema": Color(0.0, 0.45, 0.55, 0.55),
	"aislado": Color(0.45, 0.10, 0.50, 0.55),
}
const TEXTO_CUENTA := {
	"sistema": "Reinicio en %d s",
	"aislado": "No te vayas... %d",
}

const SONIDO_GOLPE := preload("res://assets/sounds/knock-fuerte.mp3")

const TINTE_NPC := {
	"sistema": Color(0.25, 0.5, 0.6, 0.55),
	"aislado": Color(0.5, 0.3, 0.6, 0.55),
}
const PISTA := {
	"sistema": "Mirá las agujas del reloj",
	"aislado": "Lo que abrió la puerta, y después la caja",
}

var _pista_dada := false
var _ola: Node2D
var _mod: CanvasModulate
var _jugador: Node2D
var _npcs: Array[Node2D] = []
var _tenidos := {}
var _guia := "aislado"
var _perseguidor := "sistema"
var _activo := false
var _t := 0.0
var _x0 := 0.0
var _vel := 0.0
var _pulso_en := 0.0
var _ultimo := -1
var _hum: AudioStreamPlayer
var _musica: AudioStreamPlayer
func voz() -> SistemaVoz:
	return SistemaVoz.activar(get_tree())

func _ready() -> void:
	if not GameManager.flags.get("caja_abierta", false) or GameManager.flags.get("evento_terminado", false):
		return
	_jugador = get_parent().find_child("Jugador", true, false)
	if reloj == null:
		reloj = get_parent().find_child("clock", true, false)
	if _jugador == null or reloj == null:
		push_error("EventoSistema: no encuentro al jugador o al reloj.")
		return
	if GameManager.flags.get("evento_iniciado", false):
		_guia = "sistema" if GameManager.flags.get("confianza_sistema", false) else "aislado"
		await get_tree().process_frame
		_empezar()
		return
	GameManager.flags["evento_iniciado"] = true
	await _introduccion()
	_empezar()

func _introduccion() -> void:
	await get_tree().create_timer(1.5).timeout
	var c = Global.caja_dialogo
	# la plaza vuelve a ser la de antes
	for k in GameManager.flags.keys():
		if String(k).begins_with("etapa_vista_"):
			GameManager.flags.erase(k)
	GameManager.flags["reloj_congelado"] = true

	await voz().decir(["Contacto con el aislado: registrado.",
			"Usuario detectado: %s." % SistemaVoz.usuario()])
	
	var eleccion := GameManager.eleccion_aislado()
	var antes: Array = ["No le hagas caso."]
	if eleccion == 0:
		antes = ["No le hagas caso.", "Me dijiste que me creías. Sostenelo."]
	elif eleccion == 1:
		antes = ["Ya sé que no me creés.", "Pero a él tampoco le creas."]
	c.iniciar_dialogo(antes, "aislado")
	await c.dialogo_terminado
	var r: int = await voz().preguntar("SISTEMA",
			"Puedo corregir esto. Solo necesito que me ayudes.\n\n¿Me ayudás, %s?" % SistemaVoz.usuario(),
			["Sí", "No"])
	var con_sistema := (r == 0)
	GameManager.flags["confianza_sistema"] = con_sistema
	GameManager.flags["confianza_aislado"] = not con_sistema
	_guia = "sistema" if con_sistema else "aislado"

	if con_sistema:
		if eleccion == 0:
			c.iniciar_dialogo(["...Me dijiste que me creías."], "aislado")
			await c.dialogo_terminado
		await voz().decir(["Bien. Al reloj de la plaza. Ahora."])
	else:
		if eleccion == 1:
			c.iniciar_dialogo(["...Al final me creíste."], "aislado")
			await c.dialogo_terminado
		c.iniciar_dialogo(["Al reloj de la plaza. Rápido. No te frenes."], "aislado")
		await c.dialogo_terminado

func _empezar() -> void:
	_perseguidor = "aislado" if _guia == "sistema" else "sistema"
	_ola = Node2D.new()
	_ola.set_script(preload("res://scripts/ola_reinicio.gd"))
	_ola.set("color", COLOR_OLA[_perseguidor])
	get_parent().add_child(_ola)
	if GameManager.flags.has("evento_x0"):
		_x0 = GameManager.flags["evento_x0"]
		_t = GameManager.flags.get("evento_t", 0.0)
	else:
		_x0 = minf(_jugador.global_position.x, reloj.global_position.x) - distancia_inicial
		GameManager.flags["evento_x0"] = _x0
	_vel = (reloj.global_position.x - _x0) / segundos
	_pista_dada = _t / segundos >= 0.5
	_ola.set("borde_x", _x0)
	_mod = CanvasModulate.new()
	get_parent().add_child(_mod)
	var grupo := get_parent().get_node_or_null("NPCs")
	if grupo:
		for n in grupo.get_children():
			if n is Node2D:
				_npcs.append(n)
	GameManager.set_objetivo("Todo está en orden", "pueblo")
	GameManager.set_objetivo("Al reloj de la plaza", _guia)
	_activo = true

func _process(delta: float) -> void:
	if not _activo:
		return
	_t += delta
	GameManager.flags["evento_t"] = _t
	var borde := _x0 + _vel * _t
	_ola.set("borde_x", borde)
	var dist := _jugador.global_position.x - borde                    # cuánto falta para que te alcance
	var cercania := 1.0 - clampf(dist / distancia_inicial, 0.0, 1.0)  # 0 lejos, 1 encima
	_mod.color = Color.WHITE.lerp(Color(0.55, 0.5, 0.7), cercania)

	if _t / segundos >= 0.5 and not _pista_dada:
		_pista_dada = true
		GameManager.set_objetivo(PISTA[_guia], _guia)

	var restante := int(ceil(maxf(dist, 0.0) / _vel))
	if restante != _ultimo:
		_ultimo = restante
		GameManager.set_objetivo(TEXTO_CUENTA[_perseguidor] % restante, _perseguidor)

	for n in _npcs:
		if is_instance_valid(n) and not _tenidos.has(n) and n.global_position.x < borde:
			_tenidos[n] = true
			if _perseguidor == "sistema":
				create_tween().tween_property(n, "modulate:a", 0.0, 0.6)   # se borran
			else:
				create_tween().tween_property(n, "modulate", TINTE_NPC["aislado"], 0.4)  # se congelan

	if _perseguidor == "sistema":
		GlitchFx.activar(get_tree()).fuerza(cercania * 0.5)
		if _hum == null:
			_hum = AudioStreamPlayer.new()
			_hum.stream = load("res://assets/sounds/sistema/sys_hum.wav")
			add_child(_hum)
			_hum.play()
			_hum.finished.connect(_hum.play)
		_hum.volume_db = lerpf(-30.0, -4.0, cercania)

	_pulso_en -= delta
	if _pulso_en <= 0.0:
		_pulso(cercania)
		_pulso_en = lerpf(1.3, 0.35, cercania)

	if GameManager.flags.get("reloj_resuelto", false):
		_terminar(true)
	elif dist <= 0.0:
		_terminar(false)

func _pulso(cercania: float) -> void:
	var aislado := _perseguidor == "aislado"
	var audio: AudioStream = SONIDO_GOLPE if aislado else sonido_pulso
	if audio:
		var p := AudioStreamPlayer.new()
		p.stream = audio
		p.volume_db = lerpf(-24.0, 0.0, cercania)
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	var cam := get_viewport().get_camera_2d()
	if cam:
		var f := lerpf(1.5, 7.0, cercania) if aislado else lerpf(1.0, 3.0, cercania)
		var t := create_tween()
		t.tween_property(cam, "offset", Vector2(randf_range(-f, f), randf_range(-f, f)), 0.04)
		t.tween_property(cam, "offset", Vector2.ZERO, 0.08)

func _terminar(resuelto: bool) -> void:
	_activo = false
	GameManager.flags["evento_terminado"] = true
	# si te alcanzó con el teclado o una inspección abierta, se cierran (si no, quedan encima del final)
	KeypadUi.cerrar()
	if InspeccionUI.abierto:
		InspeccionUI.cerrar()
	if is_instance_valid(Global.inventario_ui) and Global.inventario_ui.abierto:
		Global.inventario_ui.panel.visible = false
		Global.inventario_ui.panel_desc.visible = false
	await get_tree().process_frame
	GameManager.quitar_objetivo("sistema")
	GameManager.quitar_objetivo("aislado")
	await GameManager.quitar_objetivo("pueblo")
	var c = Global.caja_dialogo
	if resuelto:
		var rompe := _guia == "aislado"
		var linea := "Rompelo. Así nadie vuelve a repetir el día." if rompe else "Dejalo detenido. Que puedan despertar."
		c.iniciar_dialogo([linea], "aislado")
		await c.dialogo_terminado
		await voz().decir(["Reiniciá. Es lo único que los mantiene a salvo."])
		var i: int = await voz().preguntar("SISTEMA", "El panel espera una orden.",
				["Reiniciar el reloj", "Romperlo" if rompe else "Dejarlo detenido"])
		if i == 1 and rompe:
			await voz().preguntar("SISTEMA", "Advertencia: la ruptura es irreversible.\nSin el reinicio, no puedo garantizar su seguridad.", ["Continuar"])
			GameManager.flags["final_roto"] = true
		elif i == 1:
			GameManager.flags["final_1"] = true
		else:
			GameManager.flags["final_0"] = true
	else:
		if _perseguidor == "sistema":
			await voz().decir(["Reinicio completado."])
			GameManager.flags["final_tiempo_sistema"] = true
		else:
			c.iniciar_dialogo(["...Quedate. Por favor."], "aislado")
			await c.dialogo_terminado
			GameManager.flags["final_tiempo_aislado"] = true
	await get_tree().create_timer(0.5).timeout
	Transicion.ir_a(escena_final, 1.5)
