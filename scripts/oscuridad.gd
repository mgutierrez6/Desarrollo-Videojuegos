extends Node
# Casa a oscuras: halo tenue alrededor del jugador; la linterna lo enciende de verdad.

@export var jugador: Node2D
@export var item_linterna := "LinternaPrendida"
@export var color_oscuro := Color(0.051, 0.051, 0.102, 1.0)

@export_group("Sin linterna (penumbra)")
@export var escala_apagada := 0.5        # tamaño del halo
@export_range(0.0, 1.0) var energia_apagada := 0.3   # qué tan fuerte brilla

@export_group("Con linterna")
@export var escala_encendida := 0.9
@export_range(0.0, 2.0) var energia_encendida := 1.0

@export_group("Prueba")
@export var dar_linterna_para_probar := true

var _luz: PointLight2D

func _ready() -> void:
	if jugador == null:
		jugador = get_tree().current_scene.find_child("Jugador", true, false)
	if jugador == null:
		push_error("Oscuridad: no encontré al jugador.")
		return

	var mod := CanvasModulate.new()
	mod.color = color_oscuro
	add_child(mod)

	_luz = PointLight2D.new()
	_luz.texture = _crear_textura()
	_luz.position = Vector2(0, -6)            # ajustá según el origen del jugador
	_luz.texture_scale = maxf(escala_apagada, 0.01)
	_luz.energy = energia_apagada
	jugador.add_child(_luz)

	if dar_linterna_para_probar:
		GameManager.agregar_item(item_linterna)

func _process(delta: float) -> void:
	if _luz == null:
		return
	var con_linterna: bool = GameManager.item_seleccionado == item_linterna
	var escala := escala_encendida if con_linterna else escala_apagada
	var energia := energia_encendida if con_linterna else energia_apagada
	_luz.texture_scale = maxf(lerpf(_luz.texture_scale, escala, 8.0 * delta), 0.01)
	_luz.energy = lerpf(_luz.energy, energia, 8.0 * delta)

func _crear_textura() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
