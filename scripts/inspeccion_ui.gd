extends CanvasLayer

var abierto := false
var _frame_apertura := -1
var _imagen: TextureRect
var _texto: Label
var _frame_cierre := -1

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
	caja.add_theme_constant_override("separation", 16)
	margen.add_child(caja)

	_imagen = TextureRect.new()
	_imagen.custom_minimum_size = Vector2(400, 300)
	_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	caja.add_child(_imagen)

	_texto = Label.new()
	_texto.custom_minimum_size = Vector2(400, 0)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_texto)

func mostrar(textura: Texture2D, texto: String) -> void:
	# ignora si ya está abierta o si se acaba de cerrar en este mismo frame
	if abierto or Engine.get_process_frames() == _frame_cierre:
		return
	_imagen.texture = textura
	_imagen.visible = textura != null
	_texto.text = texto
	visible = true
	abierto = true
	_frame_apertura = Engine.get_process_frames()

func cerrar() -> void:
	visible = false
	abierto = false
	_frame_cierre = Engine.get_process_frames()

func _input(event: InputEvent) -> void:
	if not abierto:
		return
	if Engine.get_process_frames() == _frame_apertura:
		return
	var presionada = false
	if event is InputEventKey and event.pressed and not event.echo:
		presionada = true
	elif event is InputEventMouseButton and event.pressed:
		presionada = true
	elif event is InputEventJoypadButton and event.pressed:
		presionada = true
	if presionada:
		cerrar()
		get_viewport().set_input_as_handled()
