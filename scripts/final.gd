extends Control
# Epílogo: texto centrado sobre negro, según lo que decidiste.

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

const TAM_TEXTO := 28
const TAM_TITULO := 72   # probá 64 / 72 / 84; si la fuente se ve borrosa, usá múltiplos de su tamaño nativo

const RUIDO := "#@%&?/\\|01"
const COLOR_NARRACION := Color(0.85, 0.85, 0.9)
const COLOR_AISLADO := Color(0.75, 0.5, 0.95)
const COLOR_SISTEMA := Color(0.2, 0.7, 0.8)

# SOLO PARA DEBUG: -1 = decide por los flags. 0..3 fuerza un final desde el inspector.
# (Antes estaba en 2, y eso hacía que cualquier partida sin flag "tiempo_*" cayera en final roto.)
@export var fin := -1

var _label: Label
var _salto := false
var _base := ""                      # texto limpio de la línea actual
var _color_linea := COLOR_NARRACION  # color "oficial" de la línea actual
var _glitch := 0.0                   # intensidad del glitch de texto (0 a 1)
var _en_rafaga := false              # true mientras el texto está corrupto
var _sig := 0.0                      # segundos hasta el próximo cambio limpio <-> corrupto


# Idea: el texto está LIMPIO casi todo el tiempo y se corrompe en ráfagas de ~0.1 s,
# tocando solo unas pocas letras. Así se lee siempre, pero se siente roto.
func _process(delta: float) -> void:
	if _glitch <= 0.0:
		return
	_sig -= delta
	if _sig > 0.0:
		return
	if _en_rafaga:
		_en_rafaga = false
		_mostrar_limpio()
		# más glitch -> ráfagas más seguidas (nunca más de ~2 por segundo)
		_sig = randf_range(0.7, 1.8) / (0.5 + _glitch)
	else:
		_en_rafaga = true
		_label.text = _corromper(_base, _glitch)
		_label.pivot_offset = _label.size / 2.0
		_label.rotation_degrees = randf_range(-1.5, 1.5) * _glitch
		_label.scale = Vector2(randf_range(0.96, 1.06), 1.0)
		if randf() < 0.5:
			_label.add_theme_color_override("font_color",
				[COLOR_NARRACION, COLOR_AISLADO, COLOR_SISTEMA].pick_random())
		_sig = randf_range(0.06, 0.14)


func _mostrar_limpio() -> void:
	_label.text = _base
	_label.rotation = 0.0
	_label.scale = Vector2.ONE
	_label.add_theme_color_override("font_color", _color_linea)  # restaura el color de la línea


# Reemplaza algunas LETRAS (no espacios ni puntuación) por ruido.
# Cantidad: ~30% de g sobre la cantidad de letras, mínimo 1.
func _corromper(t: String, g: float) -> String:
	var idx: Array[int] = []
	for i in t.length():
		var c := t[i]
		if c.to_lower() != c.to_upper():  # true solo para letras
			idx.append(i)
	if idx.is_empty():
		return t
	idx.shuffle()
	var n := clampi(roundi(idx.size() * g * 0.3), 1, idx.size())
	var chars := t.split("")
	for k in n:
		chars[idx[k]] = RUIDO[randi() % RUIDO.length()]
	return "".join(chars)


func _borrar(texto: String, seg: float) -> void:
	var chars := texto.split("")
	var orden := range(chars.size())
	orden.shuffle()
	var paso := seg / maxf(1.0, orden.size())
	for i in orden:
		chars[i] = " "
		_base = "".join(chars)
		if not _en_rafaga:
			_label.text = _base   # ahora el texto ya no se actualiza solo desde _process
		await get_tree().create_timer(paso).timeout


# _decir con dos parámetros más: glitch (0 a 1) y borrar
func _decir(texto: String, pausa: float = -1.0, color: Color = COLOR_NARRACION,
		glitch: float = 0.0, borrar: bool = false) -> void:
	_color_linea = color
	_label.add_theme_color_override("font_color", color)
	_base = texto
	_label.text = texto
	_glitch = glitch
	_en_rafaga = false
	_sig = randf_range(0.8, 1.4)  # primera ráfaga recién cuando ya se leyó un poco
	var t := create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 1.2)
	await t.finished
	if borrar:
		await _borrar(texto, 3.0)
	else:
		await _esperar(pausa if pausa > 0.0 else maxf(2.2, texto.length() * 0.07))
	t = create_tween()
	t.tween_property(_label, "modulate:a", 0.0, 0.8)
	await t.finished
	_glitch = 0.0
	_en_rafaga = false
	_mostrar_limpio()
	await get_tree().create_timer(0.5).timeout


# Pantalla final con el nombre del juego, grande. Termina con un glitch corto
# antes de que el juego se cierre. En el final roto el título ya viene roto y el cierre es más duro.
func _titulo(texto: String, roto: bool) -> void:
	var fx := GlitchFx.activar(get_tree())
	_color_linea = COLOR_NARRACION
	_label.add_theme_color_override("font_color", COLOR_NARRACION)
	_label.add_theme_font_size_override("font_size", TAM_TITULO)
	_label.custom_minimum_size.x = get_viewport_rect().size.x * 0.9  # que no se parta en dos líneas
	_base = texto
	_label.text = texto
	_en_rafaga = false
	_sig = randf_range(1.0, 1.6)
	_glitch = 0.3 if roto else 0.0
	if roto:
		fx.rafagas(0.08, 0.3)

	var t := create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 1.5)
	await t.finished
	await get_tree().create_timer(2.5).timeout   # el título se queda quieto un rato, para que se lea


	_glitch = 0.0
	_en_rafaga = false
	_mostrar_limpio()
	await _micro_glitch(fx, roto)
	if roto:
		# corte seco, como un cuelgue
		_label.modulate.a = 0.0
		fx.fuerza(0.0)
		await get_tree().create_timer(1.0).timeout
	else:
		t = create_tween()
		t.tween_property(_label, "modulate:a", 0.0, 0.6)
		await t.finished
		await get_tree().create_timer(0.4).timeout


func _micro_glitch(fx: GlitchFx, fuerte: bool) -> void:
	var veces := 3 if fuerte else 1
	for i in veces:
		fx.pulso(0.7 if fuerte else 0.3, 0.12)
		_label.text = _corromper(_base, 0.8 if fuerte else 0.4)
		await get_tree().create_timer(0.1).timeout
		_label.text = _base
		await get_tree().create_timer(randf_range(0.15, 0.35)).timeout


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(700, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", TAM_TEXTO)
	_label.add_theme_color_override("font_color", COLOR_NARRACION)
	_label.modulate.a = 0.0
	centro.add_child(_label)
	await _secuencia()


func _secuencia() -> void:
	await get_tree().create_timer(2.0).timeout
	var f := GameManager.flags
	var roto := false
	if f.get("final_tiempo_aislado", false) or fin == 0:
		await _final_tiempo_aislado()
	elif f.get("final_tiempo_sistema", false) or fin == 1:
		await _final_tiempo_sistema()
	elif f.get("final_roto", false) or fin == 2:
		roto = true
		await _final_roto()
	elif f.get("final_1", false) or fin == 3:
		await _final_detenido()
	else:
		await _final_reinicio()

	if roto:
		await _titulo("S#N R@GISTRO", true)
	else:
		await _decir("Gracias por jugar.", 3.0)
		await _titulo("SIN REGISTRO", false)
	get_tree().quit()


func _final_roto() -> void:
	# El glitch sube de a poco: arranca casi imperceptible y crece línea a línea.
	var fx := GlitchFx.activar(get_tree())
	fx.rafagas(0.04, 0.15)
	await _decir("El reloj se rompió.", -1.0, COLOR_NARRACION, 0.15)
	fx.rafagas(0.06, 0.2)
	await _decir("Algo más se rompió con él.", -1.0, COLOR_NARRACION, 0.2)
	await _decir("Esto no era lo que esperaba.", -1.0, COLOR_AISLADO, 0.25)
	fx.rafagas(0.08, 0.28)
	await _decir("No sé qué va a pasar con ellos.", -1.0, COLOR_AISLADO, 0.3)
	await _decir("Por lo menos son libres ahora... no?", 10.0, COLOR_AISLADO, 0.35, true)
	# El título "S#N R@GISTRO" lo muestra _titulo(), desde _secuencia().


func _final_detenido() -> void:
	await _decir("El reloj no volvió a andar.")
	await _decir("Por primera vez, nadie repitió el día.")
	await _decir("Nadie sabe todavía qué viene después.")
	if GameManager.flags.get("confianza_aislado", false):
		await _decir("Gracias. Confiaste en mí.", -1.0, COLOR_AISLADO)
		await _decir("No sé qué va a pasar ahora, pero soy libre.", -1.0, COLOR_AISLADO)
		if GameManager.eleccion_aislado() == 1:
			await _decir("Al principio desconfiabas. Tendrías que haberte hecho caso.", -1.0, COLOR_AISLADO, 0.15)
		await _decir("Qué ingenuo fuiste.", 3.0, COLOR_AISLADO)
	else:
		await _decir("No me creías. Igual lo dejaste detenido.", -1.0, COLOR_AISLADO)
		await _decir("Soy libre. No sé qué va a pasar ahora.", 3.0, COLOR_AISLADO)


func _final_reinicio() -> void:
	await _decir("Reinicio autorizado. Gracias por tu colaboración.", -1.0, COLOR_SISTEMA)
	await _decir("El reloj volvió a andar.")
	await _decir("Luis perdió la llave de la despensa.")
	await _decir("Nadie recordó nada.")
	await _decir("Nadie, menos vos.")
	if GameManager.eleccion_aislado() == 0:
		await _decir("Me dijiste que me creías.", 3.0, COLOR_AISLADO, 0.2)
	if GameManager.flags.get("confianza_aislado", false):
		await _decir("Abajo, alguien golpea: tres, uno, cuatro. Nadie baja.")


func _final_tiempo_sistema() -> void:
	await _decir("El reloj volvió a andar solo.")
	await _decir("Luis perdió otra vez la llave de la despensa.")
	await _decir("Nadie recordó nada.")
	await _decir("Ni vos.")
	await _decir("Ah. Llegaste.", 3.0, COLOR_AISLADO)


func _final_tiempo_aislado() -> void:
	await _decir("Los golpes pararon.")
	await _decir("El reloj quedó en pausa. Nadie lo reanudó.")
	await _decir("No hubo reinicio. Tampoco hubo mañana.")
	await _decir("Luis sigue buscando la llave.")
	if GameManager.flags.get("intro_quedarse", false):
		await _decir("Te dije que todavía no. Ahora sí.", -1.0, COLOR_AISLADO)
	if GameManager.eleccion_aislado() == 0:
		await _decir("Me creíste desde el principio.", -1.0, COLOR_AISLADO)
	await _decir("Gracias por quedarte.", -1.0, COLOR_AISLADO)


func _esperar(segundos: float) -> void:
	_salto = false
	var t := 0.0
	while t < segundos and not _salto:
		await get_tree().process_frame
		t += get_process_delta_time()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		_salto = true
