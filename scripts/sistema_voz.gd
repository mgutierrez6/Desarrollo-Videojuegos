class_name SistemaVoz
extends CanvasLayer
# La voz del Sistema. No es un personaje: no usa la caja de diálogo.
#  - decir():     texto entre corchetes sobre el mundo, sin caja, con glitch y blips.
#  - preguntar(): ventana nativa del sistema operativo (estilo OneShot). Solo existe en
#                 Windows, macOS y Android; en web/Linux cae a la caja del juego.
#
# Uso (siempre después de un await, nunca directo desde un _ready):
#   var sv := SistemaVoz.activar(get_tree())
#   await sv.decir(["Contacto registrado.", "Variable externa detectada."])
#   var r: int = await sv.preguntar("SISTEMA", "¿Me ayudás?", ["Sí", "No"])
#
# Sonidos opcionales en res://assets/sounds/sistema/: sys_blip.wav y sys_glitch.wav.
# Si no están, simplemente no suenan.

signal _respondido(indice: int)

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")
const CARPETA_SFX := "res://assets/sounds/sistema/"
const RUIDO := "#@%&?/\\|01"
const COLOR_TEXTO := Color(0.55, 0.95, 1.0)

var _fondo: ColorRect
var _label: Label
var _salto := false
var _resp := -2
var _sfx := {}

static func activar(arbol: SceneTree) -> SistemaVoz:
	var v := arbol.root.get_node_or_null("SistemaVoz") as SistemaVoz
	if v == null:
		v = SistemaVoz.new()
		v.name = "SistemaVoz"
		arbol.root.add_child(v)
	return v

# Nombre de usuario del sistema operativo (el truco de OneShot). Si no hay o es raro: "usuario".
static func usuario() -> String:
	var n := OS.get_environment("USERNAME")
	if n == "":
		n = OS.get_environment("USER")
	n = n.strip_edges().replace(".", " ").replace("_", " ").capitalize()
	if n == "" or n.length() > 18:
		return "usuario"
	return n

func _ready() -> void:
	layer = 90
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.0)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(760, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", COLOR_TEXTO)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.modulate.a = 0.0
	centro.add_child(_label)
	for nombre in ["blip", "glitch"]:
		var ruta := CARPETA_SFX + "sys_%s.wav" % nombre
		if ResourceLoader.exists(ruta):
			_sfx[nombre] = load(ruta)

func decir(lineas: Array) -> void:
	Global.sistema_hablando = true
	create_tween().tween_property(_fondo, "color:a", 0.45, 0.4)
	for l in lineas:
		await _linea(str(l))
	var t := create_tween()
	t.tween_property(_fondo, "color:a", 0.0, 0.4)
	await t.finished
	Global.sistema_hablando = false

func _linea(texto: String) -> void:
	var completo := "[%s]" % texto
	_salto = false
	_pico_glitch(0.6)
	_sonar("glitch", -6.0)
	# aparece corrupto un instante y se "resuelve"
	_label.visible_characters = -1
	_label.modulate.a = 1.0
	for i in 3:
		_label.text = _corromper(completo, 0.5)
		await get_tree().create_timer(0.06).timeout
	_label.text = completo
	_label.visible_characters = 0
	for i in completo.length():
		if _salto:
			_label.visible_characters = -1
			break
		_label.visible_characters = i + 1
		if i % 2 == 0:
			_sonar("blip", -12.0)
		await get_tree().create_timer(0.03).timeout
	await _esperar(maxf(2.0, completo.length() * 0.06))
	var t := create_tween()
	t.tween_property(_label, "modulate:a", 0.0, 0.3)
	await t.finished
	_pico_glitch(0.35)
	await get_tree().create_timer(0.25).timeout

# Devuelve el índice del botón apretado (0, 1, ...). Si cierran la ventana: -1.
func preguntar(titulo: String, texto: String, botones: Array) -> int:
	Global.sistema_hablando = true
	_pico_glitch(0.8)
	_sonar("glitch", 0.0)
	await get_tree().create_timer(0.5).timeout
	var r := -1
	var hecho := false
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
		_resp = -2
		var err := DisplayServer.dialog_show(titulo, texto, PackedStringArray(botones),
				Callable(self, "_al_responder"))
		if err == OK:
			if _resp == -2:            # el callback todavía no se llamó
				await _respondido
			r = _resp
			hecho = true
	if not hecho and is_instance_valid(Global.caja_dialogo):
		# web / Linux: no hay ventana nativa, se usa la caja del juego
		r = await Global.caja_dialogo.elegir(texto, botones, "sistema")
	Global.sistema_hablando = false
	return r


func _al_responder(indice: int) -> void:
	_resp = indice
	_respondido.emit(indice)

func _esperar(segundos: float) -> void:
	_salto = false
	var t := 0.0
	while t < segundos and not _salto:
		await get_tree().process_frame
		t += get_process_delta_time()

func _corromper(t: String, g: float) -> String:
	var r := ""
	for c in t:
		r += RUIDO[randi() % RUIDO.length()] if c != " " and randf() < g else c
	return r

func _pico_glitch(v: float) -> void:
	var g := GlitchFx.activar(get_tree())
	g.fuerza(v)
	get_tree().create_timer(0.25).timeout.connect(func(): g.fuerza(0.0))

func _sonar(nombre: String, db: float) -> void:
	if not _sfx.has(nombre):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _sfx[nombre]
	p.volume_db = db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		_salto = true
