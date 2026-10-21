@tool
extends Area2D

signal etapa_ejecutada(etapa: EtapaDialogo)

@export var animaciones_npc: SpriteFrames:
	set(valor):
		animaciones_npc = valor
		if is_node_ready():
			_aplicar_animaciones()
@export var etapas: Array[EtapaDialogo] = []

@export_group("Animaciones")
@export var anim_reposo: String = "idle"      # cuando nadie le habla (ej: "buscando")
@export var anim_levantarse: String = ""      # opcional: transición de una sola vez
@export var anim_hablando: String = ""        # mientras habla (ej: "parado"); vacío = no cambia
@export var volver_a_reposo := true           # al terminar, vuelve a su pose de reposo

var _ocupado := false
var _reposo := ""

func _ready() -> void:
	_aplicar_animaciones()
	if Engine.is_editor_hint():
		return
	# recuerda la pose entre escenas
	_reposo = GameManager.flags.get("anim_" + String(name), anim_reposo)
	_reproducir(_reposo)

func _sprite() -> AnimatedSprite2D:
	return get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _aplicar_animaciones() -> void:
	var sprite := _sprite()
	if sprite == null:
		push_warning("NPC: no encuentro un nodo hijo llamado AnimatedSprite2D.")
		return
	if animaciones_npc:
		sprite.sprite_frames = animaciones_npc
	_reproducir(anim_reposo)

func _reproducir(nombre: String) -> void:
	var sprite := _sprite()
	if sprite == null or sprite.sprite_frames == null:
		return
	if nombre == "" or not sprite.sprite_frames.has_animation(nombre):
		if nombre != "":
			push_warning("NPC '%s': no existe la animación '%s'." % [name, nombre])
		var todas := sprite.sprite_frames.get_animation_names()
		if todas.is_empty():
			return
		nombre = todas[0]
	sprite.play(nombre)

func interactuar() -> void:
	if _ocupado or not Global.caja_dialogo or Global.jugador_bloqueado():
		return
	for e in etapas:
		if e != null and _cumple(e):
			await _hablar(e)
			return

func _hablar(e: EtapaDialogo) -> void:
	_ocupado = true
	await _levantarse_y_hablar()
	await _ejecutar(e)
	_ocupado = true            # _ejecutar lo apaga; lo mantenemos hasta terminar la animación
	if e.anim_reposo_despues != "":
		_reposo = e.anim_reposo_despues
		GameManager.flags["anim_" + String(name)] = _reposo
		_reproducir(_reposo)
	elif volver_a_reposo:
		_reproducir(_reposo)
	_ocupado = false

func _levantarse_y_hablar() -> void:
	var sprite := _sprite()
	if sprite and sprite.sprite_frames and anim_levantarse != "" and sprite.sprite_frames.has_animation(anim_levantarse):
		sprite.play(anim_levantarse)
		if not sprite.sprite_frames.get_animation_loop(anim_levantarse):
			await sprite.animation_finished      # solo espera si no es un loop
	if anim_hablando != "":
		_reproducir(anim_hablando)

func _cumple(e: EtapaDialogo) -> bool:
	for f in e.flags_requeridos:
		if not GameManager.flags.get(f, false):
			return false
	for f in e.flags_prohibidos:
		if GameManager.flags.get(f, false):
			return false
	for it in e.items_requeridos:
		if not GameManager.tiene_item(it):
			return false
	return true

func _ejecutar(e: EtapaDialogo) -> void:
	_ocupado = true
	if not e.texto.is_empty():
		Global.caja_dialogo.iniciar_dialogo(e.texto)
		await Global.caja_dialogo.dialogo_terminado
	if e.pregunta != "" and not e.opciones.is_empty():
		var i = await EleccionUi.elegir(e.pregunta, e.opciones)
		if e.flag_eleccion != "" and i >= 0:
			GameManager.flags[e.flag_eleccion + "_" + str(i)] = true
		if i >= 0 and i < e.respuestas.size() and e.respuestas[i] != "":
			Global.caja_dialogo.iniciar_dialogo([e.respuestas[i]])
			await Global.caja_dialogo.dialogo_terminado
	for f in e.flags_a_activar:
		GameManager.flags[f] = true
	for it in e.items_a_quitar:
		GameManager.remover_item(it)
	if e.item_a_dar != "":
		GameManager.agregar_item(e.item_a_dar)
		var nombre = GameManager.datos_items.get(e.item_a_dar, {}).get("nombre", e.item_a_dar)
		Global.caja_dialogo.iniciar_dialogo(["Recibiste: " + nombre])
	if e.objetivo_nuevo != "":
		GameManager.set_objetivo(e.objetivo_nuevo)
	_ocupado = false
	etapa_ejecutada.emit(e)
