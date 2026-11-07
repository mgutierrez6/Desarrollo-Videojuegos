extends Node2D
# Frente del reinicio: lo que queda detrás de su borde se "borra". Dibuja en coordenadas del mundo.

@export var color := Color(0.0, 0.45, 0.55, 0.55)
@export var alto := 3000.0
@export var ancho := 4000.0
var borde_x := -1000.0

func _ready() -> void:
	z_index = 50

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(borde_x - ancho, -alto * 0.5, ancho, alto), color)
	# borde con "glitch": barras que parpadean
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_msec() / 90)
	for i in range(70):
		var y := rng.randf_range(0.0, 1200.0)
		var w := rng.randf_range(6.0, 46.0)
		var h := rng.randf_range(2.0, 9.0)
		draw_rect(Rect2(borde_x - 2.0, y, w, h), color.lightened(0.45))
		draw_rect(Rect2(borde_x - w - 2.0, y + 4.0, w, 2.0), color.darkened(0.35))
