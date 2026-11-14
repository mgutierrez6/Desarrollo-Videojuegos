extends CanvasLayer
# Cartelitos de ayuda (cada uno aparece una sola vez) y pista si el jugador no avanza.
# También hay un botón "?" arriba a la derecha para pedir la pista cuando quieras.

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")
@export var segundos_sin_avanzar := 50.0

var pistas := {
	"Averiguar dónde estás": "Hablá con la gente del pueblo: acercate y apretá F.",
	"Conocer el pueblo": "Luis está frente a la tienda. Acercate y apretá F.",
	"Ayudar al señor con su llave": "Algo brilla en la fuente de la plaza. Y hay un palo tirado cerca.",
	"Seguir explorando el pueblo": "Hay una pila de piedras que parece esconder algo.",
	"Conseguir luz para la casa": "A la linterna le faltan pilas. Buscalas por el pueblo.",
	"Volver a la casa de abajo": "La linterna ya funciona. Volvé a la casa de abajo.",
	"Descubrir quién golpea": "Los golpes vienen de abajo. Buscá una puerta.",
	"Escuchá el ritmo de los golpes": "Contá los golpes de cada tanda. Siempre se repiten igual.",
	"Entrar a la casa": "La puerta ya está abierta. Volvé y entrá.",
	"Abrir la caja de los registros": "Hay un agujero en la pared con algo metálico. Necesitás algo largo y magnético.",
	"Salir de la casa": "Ya tenés lo que buscabas. Salí por la puerta.",
	"Explorar la casa": "Hay alguien más en la casa. Acercate y apretá F.",
	"Al reloj de la plaza": "El reloj está en la plaza. Acercate y apretá F.",
}

var _label: Label
var _boton: Button
var _tween: Tween
var _vistos := {}
var _firma := ""
var _t := 0.0
var _reloj := 0.0

func _ready() -> void:
	layer = 8
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -70.0
	_label.offset_bottom = -26.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# botón "?" arriba a la derecha
	_boton = Button.new()
	_boton.text = "?"
	_boton.add_theme_font_override("font", FUENTE)
	_boton.add_theme_font_size_override("font_size", 20)
	_boton.focus_mode = Control.FOCUS_NONE   # que no le robe el F / Espacio al juego
	_boton.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_boton.offset_left = -52.0
	_boton.offset_right = -16.0
	_boton.offset_top = 16.0
	_boton.offset_bottom = 52.0
	_boton.tooltip_text = "Pista (H)"
	_boton.visible = false
	_boton.pressed.connect(pedir_pista)
	add_child(_boton)

	GameManager.inventario_cambiado.connect(_on_inventario)

func mostrar(id: String, texto: String, segundos := 4.5) -> void:
	if _vistos.has(id):
		return
	_vistos[id] = true
	_decir(texto, segundos)

func _decir(texto: String, segundos: float) -> void:
	_label.text = texto
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, 0.4)
	_tween.tween_interval(segundos)
	_tween.tween_property(_label, "modulate:a", 0.0, 0.6)

# Devuelve la pista del objetivo actual, o "" si no hay ninguna
func _pista_actual() -> String:
	for texto in GameManager.objetivos.values():
		if pistas.has(texto):
			return pistas[texto]
	return ""

func pedir_pista() -> void:
	if Global.jugador_bloqueado():   # con un diálogo abierto se pisarían
		return
	_vistos["boton_pista"] = true    # ya lo encontró: no hace falta explicarle el botón
	var pista := _pista_actual()
	if pista != "":
		_t = 0.0
		_decir(pista, 6.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
		pedir_pista()

func _on_inventario() -> void:
	if GameManager.inventario.size() > 0:
		mostrar("inv", "E: inventario. Elegí un objeto, cerrá con E y apretá F frente a lo que quieras usar.")
	for clave in GameManager.recetas:
		var par: PackedStringArray = clave.split("+")
		if par.size() == 2 and GameManager.tiene_item(par[0]) and GameManager.tiene_item(par[1]):
			mostrar("comb", "Podés combinar objetos: en el inventario, elegí uno y después el otro.")

func _process(delta: float) -> void:
	_reloj += delta
	if _reloj < 0.5:
		return
	_t += _reloj
	_reloj = 0.0
	# el "?" solo se muestra si hay una pista para dar (no en el menú, la intro ni el final)
	_boton.visible = _pista_actual() != ""
	if _boton.visible:
		mostrar("boton_pista", "¿Trabado? Tocá el ? de arriba para una pista.")
	# "progreso" = cambia el inventario, los flags o algún objetivo (moverse no cuenta)
	var firma := str(GameManager.inventario.size()) + "|" + str(GameManager.flags.size()) + "|" + str(GameManager.objetivos)
	if firma != _firma:
		_firma = firma
		_t = 0.0
		return
	if _t >= segundos_sin_avanzar and not Global.jugador_bloqueado():
		_t = 0.0
		# hay un objetivo por voz (pueblo, aislado, sistema): sale la pista del primero que tenga una
		var pista := _pista_actual()
		if pista != "":
			_decir(pista, 6.0)
