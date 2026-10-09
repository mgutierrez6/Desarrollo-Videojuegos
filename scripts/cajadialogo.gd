extends CanvasLayer

signal _opcion_elegida(indice: int)
signal dialogo_terminado

var eligiendo: bool = false
var _frame_eleccion := -1
var _frame_cierre := -1
var _panel_opc: NinePatchRect
var _caja_opc: VBoxContainer
var _botones: Array[Button] = []
var _textos_opc: Array[String] = []

@onready var panel: NinePatchRect = $panel
@onready var label: RichTextLabel = $panel/label

var visible_dialogo: bool = false
var paginas_dialogo: Array = []
var indice_pagina: int = 0
var tween_texto: Tween

func _ready() -> void:
	Global.caja_dialogo = self
	panel.hide()

func iniciar_dialogo(lista_textos: Array) -> void:
	paginas_dialogo = lista_textos
	indice_pagina = 0
	panel.show()
	visible_dialogo = true
	mostrar_pagina_actual()

func mostrar_pagina_actual() -> void:
	var texto_actual = paginas_dialogo[indice_pagina]
	label.text = texto_actual
	label.visible_characters = 0
	
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		
	tween_texto = create_tween()
	var tiempo = texto_actual.length() * 0.03
	tween_texto.tween_property(label, "visible_characters", texto_actual.length(), tiempo)

func avanzar_dialogo() -> void:
	# Si todavía está escribiendo la frase actual, la completa
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		label.visible_characters = label.text.length()
		return

	# Si ya terminó de escribir, pasamos a la siguiente página
	indice_pagina += 1
	if indice_pagina < paginas_dialogo.size():
		mostrar_pagina_actual()
	else:
		ocultar_mensaje() # Se acabaron las páginas, cerramos

func ocultar_mensaje() -> void:
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
	panel.hide()
	visible_dialogo = false
	dialogo_terminado.emit()

func _unhandled_input(event: InputEvent) -> void:
	if eligiendo:
		if event.is_action_pressed("interactuar") and Engine.get_process_frames() != _frame_eleccion:
			_confirmar_foco()
			get_viewport().set_input_as_handled()
		return
	if visible_dialogo and event.is_action_pressed("interactuar"):
		avanzar_dialogo()
		get_viewport().set_input_as_handled()

# Uso: var i = await Global.caja_dialogo.elegir("¿Entrás?", ["Entrar", "No entrar"])
func elegir(pregunta: String, opciones: Array) -> int:
	if eligiendo or Engine.get_process_frames() == _frame_cierre:
		return -1
	eligiendo = true
	_frame_eleccion = Engine.get_process_frames()

	# la pregunta sale en la caja de diálogo
	paginas_dialogo = [pregunta]
	indice_pagina = 0
	panel.show()
	mostrar_pagina_actual()

	# las opciones salen en un segundo cuadro con el mismo estilo
	_construir_panel_opciones()
	for b in _botones:
		b.queue_free()
	_botones.clear()
	_textos_opc.clear()
	for i in range(opciones.size()):
		_textos_opc.append(str(opciones[i]))
		_botones.append(_crear_boton_opcion(i))
		_caja_opc.add_child(_botones[i])
	_actualizar_cursor()

	await get_tree().process_frame   # espera a que Godot calcule los tamaños
	var margen := 32.0
	var tam: Vector2 = _caja_opc.get_combined_minimum_size() + Vector2(margen, margen)
	tam.x = max(tam.x, 260.0)
	_panel_opc.size = tam
	var r: Rect2 = panel.get_global_rect()
	var y: float = r.position.y - tam.y - 8.0       # arriba de la caja...
	if y < 0.0:
		y = r.end.y + 8.0                           # ...o abajo si no entra
	_panel_opc.global_position = Vector2(r.end.x - tam.x, y)
	_panel_opc.show()
	_botones[0].grab_focus()

	var indice: int = await _opcion_elegida

	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
	_panel_opc.hide()
	panel.hide()
	eligiendo = false
	_frame_cierre = Engine.get_process_frames()
	return indice

func _construir_panel_opciones() -> void:
	if _panel_opc:
		return
	_panel_opc = NinePatchRect.new()
	_panel_opc.texture = panel.texture
	_panel_opc.region_rect = panel.region_rect
	_panel_opc.patch_margin_left = panel.patch_margin_left
	_panel_opc.patch_margin_right = panel.patch_margin_right
	_panel_opc.patch_margin_top = panel.patch_margin_top
	_panel_opc.patch_margin_bottom = panel.patch_margin_bottom
	_panel_opc.axis_stretch_horizontal = panel.axis_stretch_horizontal
	_panel_opc.axis_stretch_vertical = panel.axis_stretch_vertical
	_panel_opc.texture_filter = panel.texture_filter
	_panel_opc.hide()
	add_child(_panel_opc)

	var margen = MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	_panel_opc.add_child(margen)

	_caja_opc = VBoxContainer.new()
	_caja_opc.add_theme_constant_override("separation", 6)
	margen.add_child(_caja_opc)

func _crear_boton_opcion(i: int) -> Button:
	var b = Button.new()
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# misma fuente y color que el texto del diálogo
	b.add_theme_font_override("font", label.get_theme_font("normal_font"))
	b.add_theme_font_size_override("font_size", label.get_theme_font_size("normal_font_size"))
	b.add_theme_color_override("font_color", label.get_theme_color("default_color"))
	b.add_theme_color_override("font_focus_color", Color(1, 1, 0.4))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.4))
	# sin fondos ni recuadro de foco: solo texto
	for estilo in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
	b.pressed.connect(_opcion_elegida.emit.bind(i))
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(_actualizar_cursor)
	b.focus_exited.connect(_actualizar_cursor)
	return b

func _actualizar_cursor() -> void:
	for i in range(_botones.size()):
		var prefijo := "> " if _botones[i].has_focus() else "   "
		_botones[i].text = prefijo + _textos_opc[i]

func _confirmar_foco() -> void:
	for i in range(_botones.size()):
		if _botones[i].has_focus():
			_opcion_elegida.emit(i)
			return
