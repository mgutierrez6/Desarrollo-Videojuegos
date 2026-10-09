extends CanvasLayer
# Keypad con la misma estética que la caja de diálogo (dialogo.png + BoldPixels).
# Se usa igual que antes:  var ok = await KeypadUi.abrir("1234")
# Controles: mouse, números del teclado, flechas + F / Enter, Retroceso para borrar, Esc para salir.

signal _terminado(ok: bool)

const TEXTURA := preload("res://assets/ui/dialogo.png")
const FUENTE := preload("res://assets/ui/BoldPixels.ttf")
const COLOR_TEXTO := Color(0.41391832, 0.2701292, 0.2332739, 1)   # el mismo marrón del diálogo
const COLOR_FOCO := Color(1, 1, 0.4)                               # el mismo amarillo de las opciones
const COLOR_ERROR := Color(0.65, 0.18, 0.15)

var abierto := false
var _codigo_correcto := ""
var _ingresado := ""
var _frame_apertura := -1

var _panel: NinePatchRect
var _margen: MarginContainer
var _display: Label
var _mensaje: Label
var _botones: Array[Button] = []

func _ready() -> void:
	layer = 10
	visible = false

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	# mismo recuadro que la caja de diálogo
	_panel = NinePatchRect.new()
	_panel.texture = TEXTURA
	_panel.patch_margin_left = 6
	_panel.patch_margin_top = 6
	_panel.patch_margin_right = 6
	_panel.patch_margin_bottom = 6
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centro.add_child(_panel)

	_margen = MarginContainer.new()
	_margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		_margen.add_theme_constant_override("margin_" + lado, 32)
	for lado in ["top", "bottom"]:
		_margen.add_theme_constant_override("margin_" + lado, 22)
	_panel.add_child(_margen)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 10)
	_margen.add_child(caja)

	_display = _crear_label(40)
	caja.add_child(_display)

	var grilla = GridContainer.new()
	grilla.columns = 3
	grilla.add_theme_constant_override("h_separation", 28)
	grilla.add_theme_constant_override("v_separation", 4)
	grilla.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(grilla)

	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Borrar", "0", "OK"]:
		var b = _crear_boton(t)
		grilla.add_child(b)
		_botones.append(b)

	_mensaje = _crear_label(22)
	_mensaje.add_theme_color_override("font_color", COLOR_ERROR)
	caja.add_child(_mensaje)

	_ajustar_tamano.call_deferred()

func _crear_label(tam: int) -> Label:
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", COLOR_TEXTO)
	return l

# Botones de solo texto, igual que las opciones del diálogo
func _crear_boton(t: String) -> Button:
	var b = Button.new()
	b.text = t
	b.flat = true
	b.custom_minimum_size = Vector2(56, 40)
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", COLOR_TEXTO)
	b.add_theme_color_override("font_focus_color", COLOR_FOCO)
	b.add_theme_color_override("font_hover_color", COLOR_FOCO)
	b.add_theme_color_override("font_pressed_color", COLOR_FOCO)
	b.add_theme_color_override("font_hover_pressed_color", COLOR_FOCO)
	for estilo in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
	b.pressed.connect(_on_tecla.bind(t))
	b.mouse_entered.connect(b.grab_focus)
	return b

func _ajustar_tamano() -> void:
	var tam: Vector2 = _margen.get_combined_minimum_size()
	tam.x = max(tam.x, 300.0)
	_panel.custom_minimum_size = tam

func abrir(codigo: String) -> bool:
	_codigo_correcto = codigo
	_ingresado = ""
	_mensaje.text = ""
	_actualizar()
	_ajustar_tamano()
	visible = true
	abierto = true
	_frame_apertura = Engine.get_process_frames()
	_botones[0].grab_focus()
	var ok: bool = await _terminado
	visible = false
	abierto = false
	return ok

func _actualizar() -> void:
	var s = _ingresado
	while s.length() < _codigo_correcto.length():
		s += "_"
	_display.text = " ".join(s.split(""))

func _on_tecla(t: String) -> void:
	match t:
		"Borrar":
			_ingresado = _ingresado.substr(0, _ingresado.length() - 1)
			_mensaje.text = ""
		"OK":
			if _ingresado == _codigo_correcto:
				_terminado.emit(true)
				return
			_mensaje.text = "Código incorrecto"
			_ingresado = ""
		_:
			if _ingresado.length() < _codigo_correcto.length():
				_ingresado += t
				_mensaje.text = ""
	_actualizar()

# _input (y no _unhandled_input) para que Enter sea siempre OK y F/Espacio no aprieten dos veces
func _input(event: InputEvent) -> void:
	if not abierto or Engine.get_process_frames() == _frame_apertura:
		return

	if event.is_action_pressed("ui_cancel"):          # Esc: salir sin resolver
		_terminado.emit(false)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interactuar"):         # F: aprieta el botón marcado
		for b in _botones:
			if b.has_focus():
				b.pressed.emit()
				break
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = event.keycode
		if k >= KEY_0 and k <= KEY_9:
			_on_tecla(str(k - KEY_0))
		elif k >= KEY_KP_0 and k <= KEY_KP_9:
			_on_tecla(str(k - KEY_KP_0))
		elif k == KEY_BACKSPACE:
			_on_tecla("Borrar")
		elif k == KEY_ENTER or k == KEY_KP_ENTER:
			_on_tecla("OK")
		else:
			return
		get_viewport().set_input_as_handled()
