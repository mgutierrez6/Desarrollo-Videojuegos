extends CanvasLayer
# Autoload (ObjetivoUi): muestra el objetivo actual arriba a la izquierda,
# con el mismo recuadro, fuente y color que la caja de diálogo.

const TEXTURA := preload("res://assets/ui/dialogo.png")
const FUENTE := preload("res://assets/ui/BoldPixels.ttf")
const COLOR_TEXTO := Color(0.41391832, 0.2701292, 0.2332739, 1)

var _panel: PanelContainer
var _label: Label

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

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.custom_minimum_size = Vector2(280, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", COLOR_TEXTO)
	_panel.add_child(_label)

	GameManager.objetivo_cambiado.connect(_on_cambio)
	_on_cambio(GameManager.objetivo_actual)

func _on_cambio(texto: String) -> void:
	_panel.visible = texto != ""
	_label.text = "Objetivo:\n- " + texto.replace("\n", "\n- ")
	_panel.reset_size()
	# destello al cambiar, para que se note
	_panel.modulate = Color(1, 1, 0.5)
	create_tween().tween_property(_panel, "modulate", Color.WHITE, 0.8)
