extends CanvasLayer

signal _terminado(ok: bool)

var abierto := false
var _codigo_correcto := ""
var _ingresado := ""
var _display: Label
var _mensaje: Label

func _ready():
	layer = 10
	visible = false

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro = CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var panel = PanelContainer.new()
	centro.add_child(panel)
	var margen = MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)

	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	_display = Label.new()
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_display.add_theme_font_size_override("font_size", 32)
	caja.add_child(_display)

	var grilla = GridContainer.new()
	grilla.columns = 3
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	caja.add_child(grilla)

	for t in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "Borrar", "0", "OK"]:
		var b = Button.new()
		b.text = t
		b.custom_minimum_size = Vector2(80, 60)
		b.pressed.connect(_on_tecla.bind(t))
		grilla.add_child(b)

	_mensaje = Label.new()
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_mensaje)

# Se usa así:  var ok = await KeypadUI.abrir("1234")
func abrir(codigo: String) -> bool:
	_codigo_correcto = codigo
	_ingresado = ""
	_mensaje.text = ""
	_actualizar()
	visible = true
	abierto = true
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
		"OK":
			if _ingresado == _codigo_correcto:
				_terminado.emit(true)
			else:
				_mensaje.text = "Código incorrecto"
				_ingresado = ""
		_:
			if _ingresado.length() < _codigo_correcto.length():
				_ingresado += t
	_actualizar()

func _unhandled_input(event: InputEvent) -> void:
	if abierto and event.is_action_pressed("ui_cancel"):   # Esc para salir
		_terminado.emit(false)
		get_viewport().set_input_as_handled()
