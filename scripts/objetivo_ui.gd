extends CanvasLayer
# Autoload (ObjetivoUi): objetivos arriba a la izquierda, una línea por "voz", cada una con su color.

const TEXTURA := preload("res://assets/ui/dialogo.png")
const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

const ORDEN := ["pueblo", "aislado", "sistema"]
const COLORES := {
	"pueblo": Color(0.41391832, 0.2701292, 0.2332739, 1),   # Marrón de siempre
	"aislado": Color(0.605, 0.242, 0.69, 1.0),            # Violeta más claro
	"sistema": Color(0.0, 0.65, 0.78, 1.0),                # Celeste frío más claro
}

var _panel: PanelContainer
var _caja: VBoxContainer

func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(16, 16)

	var estilo = StyleBoxTexture.new()
	estilo.texture = TEXTURA
	estilo.texture_margin_left = 6
	estilo.texture_margin_top = 6
	estilo.texture_margin_right = 6
	estilo.texture_margin_bottom = 6
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", estilo)
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_panel)

	_caja = VBoxContainer.new()
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja.add_theme_constant_override("separation", 4)
	_panel.add_child(_caja)

	GameManager.objetivos_cambiados.connect(_actualizar)
	_actualizar()

func _crear_linea(texto: String, color: Color, con_borde: bool = false) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.custom_minimum_size = Vector2(280, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.text = texto
	return l

func _actualizar() -> void:
	for h in _caja.get_children():
		_caja.remove_child(h)
		h.queue_free()
	var hay := false
	for f in ORDEN:
		if GameManager.objetivos.has(f):
			hay = true
	if hay:
		_caja.add_child(_crear_linea("Objetivo:", COLORES["pueblo"], false))
	for f in ORDEN:
		if GameManager.objetivos.has(f):
			var t: String = GameManager.objetivos[f]
			# Aplica borde si es aislado o sistema
			var necesita_borde: bool = (f == "aislado" or f == "sistema")
			_caja.add_child(_crear_linea("- " + t.replace("\n", "\n- "), COLORES[f], necesita_borde))
	_panel.visible = hay
	_panel.reset_size()
	# destello al cambiar, para que se note
	_panel.modulate = Color(1, 1, 0.5)
	create_tween().tween_property(_panel, "modulate", Color.WHITE, 0.8)
