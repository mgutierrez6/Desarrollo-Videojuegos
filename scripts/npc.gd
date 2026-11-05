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

@export_group("Guía")
@export var altura_marca := 52.0              # altura de la "!" sobre el NPC

var _ocupado := false
var _reposo := ""
var _marca: Label

func _ready() -> void:
	_aplicar_animaciones()
	if Engine.is_editor_hint():
		return
	_crear_marca()
	# recuerda la pose entre escenas
	_reposo = GameManager.flags.get("anim_" + String(name), anim_reposo)
	_reproducir(_reposo)

func _crear_marca() -> void:
	_marca = Label.new()
	_marca.text = "!"
	_marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_marca.custom_minimum_size = Vector2(16, 0)
	_marca.add_theme_font_size_override("font_size", 14)
	_marca.add_theme_color_override("font_color", Color(1.0, 0.902, 0.431, 1.0))
	_marca.add_theme_color_override("font_outline_color", Color.BLACK)
	_marca.add_theme_constant_override("outline_size", 4)
	_marca.position = Vector2(-8, -altura_marca)
	_marca.z_index = 10
	_marca.visible = false
	add_child(_marca)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _marca == null:
		return
	_marca.visible = hay_algo_para_hacer()
	if _marca.visible:
		_marca.position = Vector2(-8, -altura_marca + sin(Time.get_ticks_msec() / 200.0) * 1.8)

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

func _indice_etapa_actual() -> int:
	for i in range(etapas.size()):
		if etapas[i] != null and _cumple(etapas[i]):
			return i
	return -1

# true mientras haya una etapa nueva que todavía no escuchaste
func hay_algo_para_hacer() -> bool:
	if _ocupado:
		return false
	var i := _indice_etapa_actual()
	if i < 0 or not etapas[i].marca_pendiente:
		return false
	return GameManager.flags.get("etapa_vista_" + String(name), -1) != i

func interactuar() -> void:
	if _ocupado or not Global.caja_dialogo or Global.jugador_bloqueado():
		return
	var i := _indice_etapa_actual()
	if i < 0:
		return
	await _hablar(etapas[i])
	GameManager.flags["etapa_vista_" + String(name)] = i

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
	
	# 1. Diálogo principal con la fuente del objetivo
	if not e.texto.is_empty():
		Global.caja_dialogo.iniciar_dialogo(e.texto, e.fuente_objetivo)
		await Global.caja_dialogo.dialogo_terminado

	# 2. Elección / Pregunta (si usa la caja de diálogo o EleccionUi)
	if e.pregunta != "" and not e.opciones.is_empty():
		var i = await Global.caja_dialogo.elegir(e.pregunta, e.opciones, e.fuente_objetivo)
		if e.flag_eleccion != "" and i >= 0:
			GameManager.flags[e.flag_eleccion + "_" + str(i)] = true
		if i >= 0 and i < e.respuestas.size() and e.respuestas[i] != "":
			Global.caja_dialogo.iniciar_dialogo([e.respuestas[i]], e.fuente_objetivo)
			await Global.caja_dialogo.dialogo_terminado

	# 3. Flags e Items
	for f in e.flags_a_activar:
		GameManager.flags[f] = true
	for it in e.items_a_quitar:
		GameManager.remover_item(it)
	if e.item_a_dar != "":
		GameManager.agregar_item(e.item_a_dar)
		var nombre = GameManager.datos_items.get(e.item_a_dar, {}).get("nombre", e.item_a_dar)
		Global.caja_dialogo.iniciar_dialogo(["Recibiste: " + nombre], e.fuente_objetivo)

	# 4. Actualizar objetivo
	if e.objetivo_nuevo != "":
		GameManager.set_objetivo(e.objetivo_nuevo, e.fuente_objetivo)

	_ocupado = false
	etapa_ejecutada.emit(e)
