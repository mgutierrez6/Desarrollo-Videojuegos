extends CanvasLayer
# Cartelitos de ayuda (cada uno aparece una sola vez) y pista si el jugador no avanza.

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")
@export var segundos_sin_avanzar := 75.0

# objetivo del pueblo -> pista que sale si el jugador se queda trabado
var pistas := {
	"Hablá con Luis": "Luis está frente a la tienda. Acercate y apretá F.",
	"Encontrá la llave de Luis": "Algo brilla en la fuente de la plaza.",
	"Buscá algo largo": "Hay un palo tirado cerca de la plaza.",
}

var _label: Label
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
	# "progreso" = cambia el inventario, los flags o el objetivo (moverse no cuenta)
	var firma := str(GameManager.inventario.size()) + "|" + str(GameManager.flags.size()) + "|" + GameManager.objetivo_actual
	if firma != _firma:
		_firma = firma
		_t = 0.0
		return
	if _t >= segundos_sin_avanzar and not Global.jugador_bloqueado():
		_t = 0.0
		var p: String = pistas.get(GameManager.objetivo_actual, "")
		if p != "":
			_decir(p, 6.0)
