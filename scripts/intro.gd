extends Control

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

# Color de la voz. Violeta = Milo (como su objetivo). Para dejarla como el Sistema,
# probá con Color(0.2, 0.7, 0.8): un celeste más claro, que se lea sobre negro.
const COLOR_VOZ := Color(0.75, 0.5, 0.95)

signal _elegida(indice: int)

var _label: Label
var _caja_opc: VBoxContainer
var _opciones: Array[Button] = []
var _textos: Array = []
var _salto := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fondo = ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 28)
	centro.add_child(caja)

	_label = Label.new()
	_label.custom_minimum_size = Vector2(700, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", COLOR_VOZ)
	_label.modulate.a = 0.0
	caja.add_child(_label)

	_caja_opc = VBoxContainer.new()
	_caja_opc.add_theme_constant_override("separation", 10)
	_caja_opc.visible = false
	caja.add_child(_caja_opc)

	await _secuencia()

func _secuencia() -> void:
	await get_tree().create_timer(2.5).timeout          # negro y silencio

	await _decir("...", 2.5)
	await _decir("Ah. Llegaste.")
	await _decir("Hacía tiempo que no venía nadie.")
	await _decir("Vas a ver un pueblo tranquilo. Gente amable.")
	await _decir("Cada día es igual al anterior.")
	await _decir("Si algo se repite, no te asustes. Fijate bien.")

	var i = await _elegir("Cuando estés listo.", ["Salir", "Quedarme"])
	GameManager.flags["intro_quedarse"] = (i == 1)       # el juego se acuerda
	if i == 1:
		await _decir("Quedarte no es una opción.")
		await _decir("Todavía no. Vamos, salí.")

	# las dos opciones llevan al mismo lugar
	await get_tree().create_timer(1.0).timeout
	Global.punto_spawn = "desde_casa1"
	GameManager.set_objetivo("Averiguar dónde estás")
	get_tree().change_scene_to_file("res://escenas/juego.scn")

# Una línea con fundido de entrada y salida; F salta la espera
func _decir(texto: String, pausa: float = -1.0) -> void:
	_label.text = texto
	var t = create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 1.2)
	await t.finished
	await _esperar(pausa if pausa > 0.0 else max(1.8, texto.length() * 0.06))
	t = create_tween()
	t.tween_property(_label, "modulate:a", 0.0, 0.8)
	await t.finished
	await get_tree().create_timer(0.6).timeout           # silencio entre líneas

func _esperar(segundos: float) -> void:
	_salto = false
	var t := 0.0
	while t < segundos and not _salto:
		await get_tree().process_frame
		t += get_process_delta_time()

func _elegir(pregunta: String, opciones: Array) -> int:
	_label.text = pregunta
	var t = create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 1.2)
	await t.finished

	_textos = opciones
	_opciones.clear()
	for i in range(opciones.size()):
		var b = Button.new()
		b.flat = true
		b.add_theme_font_override("font", FUENTE)
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", COLOR_VOZ)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		for estilo in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
		b.pressed.connect(_elegida.emit.bind(i))
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(_actualizar_cursor)
		b.focus_exited.connect(_actualizar_cursor)
		_caja_opc.add_child(b)
		_opciones.append(b)
	_actualizar_cursor()
	_caja_opc.visible = true
	_opciones[0].grab_focus.call_deferred()

	var elegido: int = await _elegida

	_caja_opc.visible = false
	t = create_tween()
	t.tween_property(_label, "modulate:a", 0.0, 0.8)
	await t.finished
	await get_tree().create_timer(0.6).timeout
	return elegido

func _actualizar_cursor() -> void:
	for i in range(_opciones.size()):
		var prefijo := "> " if _opciones[i].has_focus() else "  "
		_opciones[i].text = prefijo + str(_textos[i])

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interactuar"):
		return
	if _caja_opc.visible:
		for i in range(_opciones.size()):
			if _opciones[i].has_focus():
				_elegida.emit(i)
				return
	else:
		_salto = true
