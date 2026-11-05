extends Node2D
# Tecla "F" en pixel art, sobre el jugador. Hijo del CharacterBody2D.

const MARRON := Color(0.41391832, 0.2701292, 0.2332739)
const CREMA := Color(0.93, 0.87, 0.74)
const CANTO := Color(0.78, 0.68, 0.52)
const LETRA_F := ["###", "#..", "##.", "#..", "#.."]

@export var altura: int = 30            # píxeles sobre el origen del jugador
@export var demora := 0.5               # segundos cerca de algo antes de aparecer
@export var usos_para_aprender := 4     # pulsaciones con el cartel visible; 0 = nunca deja de aparecer

var _cerca := 0.0
var _usos := 0
var _mostrando := false
var _tween: Tween

func _ready() -> void:
	z_index = 20
	modulate.a = 0.0
	position = Vector2(-4, -altura)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 9, 11), MARRON)        # borde
	draw_rect(Rect2(1, 1, 7, 7), CREMA)          # cara de la tecla
	draw_rect(Rect2(1, 8, 7, 2), CANTO)          # grosor
	for y in range(LETRA_F.size()):
		for x in range(LETRA_F[y].length()):
			if LETRA_F[y][x] == "#":
				draw_rect(Rect2(3 + x, 2 + y, 1, 1), MARRON)

func _process(delta: float) -> void:
	var quiere := _hay_algo_para_hacer() and not Global.jugador_bloqueado()
	if GameManager.flags.get("tip_f_aprendido", false):
		quiere = false
	_cerca = _cerca + delta if quiere else 0.0

	var mostrar := quiere and _cerca >= demora
	if mostrar != _mostrando:
		_mostrando = mostrar
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 1.0 if mostrar else 0.0, 0.2)

	if _mostrando:
		# sube y baja de a un píxel entero, para que no se vea borroso
		position = Vector2(-4, -altura + round(sin(Time.get_ticks_msec() / 220.0)))
		if Input.is_action_just_pressed("interactuar"):
			_usos += 1
			if usos_para_aprender > 0 and _usos >= usos_para_aprender:
				GameManager.flags["tip_f_aprendido"] = true

func _hay_algo_para_hacer() -> bool:
	var zona := get_parent().get_node_or_null("Interaccion") as Area2D
	if zona == null:
		return false
	var cuerpos = zona.get_overlapping_bodies()
	var areas = zona.get_overlapping_areas()
	for el in cuerpos + areas:
		var o = el
		if not o.has_method("interactuar") and o.get_parent():
			o = o.get_parent()
		if o.has_method("hay_algo_para_hacer") and o.hay_algo_para_hacer():
			return true
	return false

func _input(event: InputEvent) -> void:
	if _mostrando and event.is_action_pressed("interactuar"):
		_usos += 1
		if usos_para_aprender > 0 and _usos >= usos_para_aprender:
			GameManager.flags["tip_f_aprendido"] = true
