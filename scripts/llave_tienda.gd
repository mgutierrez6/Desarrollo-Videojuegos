extends Area2D
# Llave que flota en la fuente y desaparece cuando alguien la pesca.

@export var flag_oculta: String = "fuente_pescada"
@export var amplitud := 1.5          # cuánto sube y baja, en píxeles
@export var velocidad := 2.0
@export var brillo := true           # un destello suave, para que se note que es interactuable

var _y0: float
var _t := 0.0

func _ready() -> void:
	_y0 = position.y
	visible = not GameManager.flags.get(flag_oculta, false)

func _process(delta: float) -> void:
	visible = not GameManager.flags.get(flag_oculta, false)
	if not visible:
		return
	_t += delta
	position.y = _y0 + sin(_t * velocidad) * amplitud
	if brillo:
		var v := 1.05 + 0.2 * sin(_t * 3.0)
		modulate = Color(v, v, v, 1.0)
