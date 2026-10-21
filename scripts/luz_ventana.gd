extends PointLight2D
# Luz que se cuela por una ventana tapada con tablas: franjas de luz que caen hacia abajo.

@export var color_luz := Color(1.0, 0.92, 0.7)    # amarillo pálido; para luz de luna probá Color(0.7, 0.8, 1.0)
@export_range(0.0, 2.0) var intensidad := 0.6
@export var ancho := 48                           # ancho del haz
@export var largo := 96                           # qué tan lejos llega hacia abajo
@export var franjas := 3                          # cuántas rendijas entre tablas
@export_range(0.1, 0.9) var grosor_franja := 0.4  # cuánto de cada franja es luz
@export var flag_encendida := ""                  # vacío = siempre; si no, se prende con ese flag

func _ready() -> void:
	texture = _crear_textura()
	color = color_luz
	energy = intensidad if _prendida() else 0.0
	offset = Vector2(0, largo * 0.5)              # el haz arranca en el nodo y cae hacia abajo

func _process(delta: float) -> void:
	var meta := intensidad if _prendida() else 0.0
	energy = lerpf(energy, meta, 4.0 * delta)

func _prendida() -> bool:
	return flag_encendida == "" or GameManager.flags.get(flag_encendida, false)

func _crear_textura() -> ImageTexture:
	var img := Image.create(ancho, largo, false, Image.FORMAT_RGBA8)
	var periodo := float(largo) / float(franjas)
	for y in range(largo):
		var vertical := 1.0 - float(y) / float(largo)             # se apaga al alejarse
		var en_franja := fmod(float(y), periodo) / periodo < grosor_franja
		for x in range(ancho):
			var lateral := 1.0 - absf(float(x) / float(ancho - 1) * 2.0 - 1.0)
			lateral = smoothstep(0.0, 0.5, lateral)               # bordes suaves
			var a := vertical * lateral * (1.0 if en_franja else 0.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
