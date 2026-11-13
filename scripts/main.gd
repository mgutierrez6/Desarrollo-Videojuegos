extends Control

const RUIDO := "#@%&?/"

@onready var titulo: Label = %Titulo
@onready var opciones := [%Iniciar, %Salir]

var textos := []
var elegida := 0
var saliendo := false

func _ready() -> void:
	for i in opciones.size():
		var op: Label = opciones[i]
		textos.append(op.text)
		op.mouse_filter = Control.MOUSE_FILTER_STOP
		op.mouse_entered.connect(elegir.bind(i))
		op.gui_input.connect(_on_click.bind(i))
	elegir(0)
	glitch_titulo()

func elegir(i: int) -> void:
	elegida = i
	for j in opciones.size():
		var op: Label = opciones[j]
		op.text = ("> " if j == i else "  ") + textos[j]

func _on_click(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activar(i)

func _unhandled_input(event: InputEvent) -> void:
	for accion in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if event.is_action_pressed(accion):
			elegir((elegida + 1) % opciones.size())
	if event.is_action_pressed("ui_accept"):
		activar(elegida)

func activar(i: int) -> void:
	if saliendo:
		return
	if i == 0:
		saliendo = true
		var fx := GlitchFx.activar(get_tree())
		fx.fuerza(0.8)
		await get_tree().create_timer(0.4).timeout
		fx.fuerza(0.0)
		Transicion.ir_a("res://escenas/intro.tscn")
	else:
		get_tree().quit()

# una letra del título se rompe un instante, cada varios segundos
func glitch_titulo() -> void:
	var original := titulo.text
	while not saliendo:
		await get_tree().create_timer(randf_range(4.0, 8.0)).timeout
		if not is_inside_tree():
			return
		var letras := original.split("")
		letras[randi() % letras.size()] = RUIDO[randi() % RUIDO.length()]
		titulo.text = "".join(letras)
		await get_tree().create_timer(0.1).timeout
		if not is_inside_tree():
			return
		titulo.text = original
