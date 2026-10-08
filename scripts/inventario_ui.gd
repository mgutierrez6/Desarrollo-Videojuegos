extends CanvasLayer

const COLUMNAS := 5
const FILAS := 2
const CASILLAS_TOTALES := COLUMNAS * FILAS      # 10
const TAM_CASILLA := Vector2(110, 110)
const SEP_H := 60    # espacio horizontal entre casillas
const SEP_V := 20    # espacio vertical entre filas
const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

@onready var panel = $Panel
@onready var panel_desc = $PanelDescrip
@onready var grilla: GridContainer = %GridContainer
@onready var lbl_info: Label = %Descripcion

func _ready():
	panel.visible = false
	panel_desc.visible = false
	grilla.columns = COLUMNAS
	lbl_info.add_theme_font_override("font", FUENTE)
	lbl_info.add_theme_font_size_override("font_size", 20)
	grilla.add_theme_constant_override("h_separation", SEP_H)
	grilla.add_theme_constant_override("v_separation", SEP_V)
	# ahora la grilla está directo en el MarginContainer: se centra en los dos ejes
	grilla.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grilla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	GameManager.inventario_cambiado.connect(actualizar)

func _unhandled_input(event):
	if event.is_action_pressed("inventario"):
		panel.visible = not panel.visible
		panel_desc.visible = panel.visible
		if panel.visible:
			actualizar()

func actualizar():
	for hijo in grilla.get_children():
		hijo.queue_free()
	for i in range(CASILLAS_TOTALES):
		if i < GameManager.inventario.size():
			grilla.add_child(_crear_casilla(GameManager.inventario[i]))
		else:
			grilla.add_child(_crear_casilla_vacia())
	_mostrar_info(GameManager.item_seleccionado)

func _crear_casilla(nombre: String) -> Button:
	var info = GameManager.datos_items[nombre]
	var b = Button.new()
	b.custom_minimum_size = TAM_CASILLA
	b.icon = info["textura"]
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.text = info["nombre"]
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", 16)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if nombre == GameManager.item_seleccionado:
		b.modulate = Color(1, 1, 0.4)  # resaltado amarillo
	b.pressed.connect(_on_casilla.bind(nombre))
	# descripción al pasar el mouse (o al enfocar con teclado)
	b.mouse_entered.connect(_mostrar_info.bind(nombre))
	b.focus_entered.connect(_mostrar_info.bind(nombre))
	b.mouse_exited.connect(_on_salir_casilla)
	return b

func _crear_casilla_vacia() -> Button:
	var b = Button.new()
	b.custom_minimum_size = TAM_CASILLA
	b.disabled = true
	b.modulate = Color(1, 1, 1, 0.35)   # se ve apagada
	return b

func _on_salir_casilla():
	# al sacar el mouse, vuelve a mostrar el ítem seleccionado (o nada)
	_mostrar_info(GameManager.item_seleccionado)

func _on_casilla(nombre: String):
	var sel = GameManager.item_seleccionado
	if sel == "" or sel == nombre:
		# seleccionar / deseleccionar
		GameManager.item_seleccionado = "" if sel == nombre else nombre
		actualizar()
		return
	# ya había uno seleccionado y toqué otro: intento combinar
	var resultado = GameManager.combinar_items(sel, nombre)
	if resultado != "":
		GameManager.item_seleccionado = ""
		actualizar()
		lbl_info.text = "Creaste: " + GameManager.datos_items[resultado]["nombre"]
	else:
		GameManager.item_seleccionado = nombre
		actualizar()
		lbl_info.text = "No parece que se puedan combinar."

func _mostrar_info(nombre: String):
	lbl_info.text = GameManager.datos_items[nombre]["descripcion"] if nombre != "" else ""
