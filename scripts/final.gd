extends Control
# Epílogo: texto centrado sobre negro, según lo que decidiste.

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

var _label: Label
var _salto := false
const RUIDO := "#@%&?/\\|01"
var _base := ""
var _glitch := 0.0
var _espera_g := 0.0
const COLOR_NARRACION := Color(0.85, 0.85, 0.9)
const COLOR_AISLADO := Color(0.75, 0.5, 0.95)
const COLOR_SISTEMA := Color(0.2, 0.7, 0.8)

func _process(delta: float) -> void:
	if _glitch <= 0.0:
		return
	_espera_g -= delta
	if _espera_g > 0.0:
		return
	_espera_g = randf_range(0.04, 0.12)
	_label.text = _corromper(_base, _glitch)
	_label.pivot_offset = _label.size / 2.0
	_label.rotation_degrees = randf_range(-2.0, 2.0) * _glitch
	_label.scale = Vector2(randf_range(0.92, 1.12), 1.0)
	if randf() < _glitch * 0.4:
		_label.add_theme_color_override("font_color",
			[COLOR_NARRACION, COLOR_AISLADO, COLOR_SISTEMA].pick_random())

func _corromper(t: String, g: float) -> String:
	var r := ""
	for c in t:
		r += RUIDO[randi() % RUIDO.length()] if c != " " and randf() < g * 0.5 else c
	return r

func _borrar(texto: String, seg: float) -> void:
	var chars := texto.split("")
	var orden := range(chars.size())
	orden.shuffle()
	var paso := seg / maxf(1.0, orden.size())
	for i in orden:
		chars[i] = " "
		_base = "".join(chars)
		await get_tree().create_timer(paso).timeout

# _decir con dos parámetros más: glitch (0 a 1) y borrar
func _decir(texto: String, pausa: float = -1.0, color: Color = COLOR_NARRACION,
		glitch: float = 0.0, borrar: bool = false) -> void:
	_label.add_theme_color_override("font_color", color)
	_base = texto
	_glitch = glitch
	_label.text = texto
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
	_label.rotation = 0.0
	_label.scale = Vector2.ONE
	await get_tree().create_timer(0.5).timeout

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
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_label.modulate.a = 0.0
	centro.add_child(_label)
	await _secuencia()

func _secuencia() -> void:
	await get_tree().create_timer(2.0).timeout
	var f := GameManager.flags
	if f.get("final_tiempo_aislado", false):
		await _final_tiempo_aislado()
	elif f.get("final_tiempo_sistema", false):
		await _final_tiempo_sistema()
	elif f.get("final_roto", false):
		await _final_roto()
		await get_tree().create_timer(2.0).timeout
		get_tree().quit()
		return
	elif f.get("final_1", false):
		await _final_detenido()
	else:
		await _final_reinicio()
	await _decir("SIN REGISTRO", 4.0)
	await _decir("Gracias por jugar.", 3.0)
	get_tree().quit()  
	
func _final_roto() -> void:
	var fx := GlitchFx.activar(get_tree())
	await _decir("El reloj se rompió.", -1.0, COLOR_NARRACION, 0.05)
	fx.fuerza(0.3, 2.0)
	await _decir("Algo más se rompió con él.", -1.0, COLOR_NARRACION, 0.2)
	await _decir("Esto no era lo que esperaba.", -1.0, COLOR_AISLADO, 0.4)
	fx.fuerza(0.7, 2.0)
	await _decir("No sé qué va a pasar con ellos.", -1.0, COLOR_AISLADO, 0.6)
	await _decir("Por lo menos son libres ahora... ¿no?", 4.0, COLOR_AISLADO, 0.5, true)
	fx.fuerza(1.0, 1.5)
	await _decir("S#N R@GISTRO", 3.0, COLOR_NARRACION, 0.9)
	fx.fuerza(0.0)

func _final_detenido() -> void:
	await _decir("El reloj no volvió a andar.")
	await _decir("Por primera vez, nadie repitió el día.")
	await _decir("Nadie sabe todavía qué viene después.")
	if GameManager.flags.get("confianza_aislado", false):
		await _decir("Gracias. Confiaste en mí.", -1.0, COLOR_AISLADO)
		await _decir("No sé qué va a pasar ahora, pero soy libre.", -1.0, COLOR_AISLADO)
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
