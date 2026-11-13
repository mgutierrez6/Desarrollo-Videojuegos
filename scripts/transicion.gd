extends CanvasLayer

var activa := false            # true mientras dura la transición (frena al jugador)
var _fondo: ColorRect

func _ready() -> void:
	layer = 128                # por encima de todo lo demás
	_fondo = ColorRect.new()
	_fondo.color = Color.BLACK
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo.modulate.a = 0.0    # empieza transparente
	add_child(_fondo)

func ir_a(ruta: String, duracion: float = 0.4) -> void:
	if activa:                 # si ya hay una en curso, ignorar (evita dobles disparos)
		return
	activa = true
	await _fundir(1.0, duracion)                 # pantalla a negro
	get_tree().change_scene_to_file(ruta)        # el cambio real, con todo tapado
	await get_tree().process_frame               # dejamos que la escena nueva arme sus nodos
	await get_tree().process_frame
	await _fundir(0.0, duracion)                 # negro a transparente
	activa = false

func _fundir(alfa: float, segundos: float) -> void:
	var t := create_tween()
	t.tween_property(_fondo, "modulate:a", alfa, segundos)
	await t.finished
