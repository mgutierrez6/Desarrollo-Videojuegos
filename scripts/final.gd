extends Control
# Epílogo: texto centrado sobre negro, según lo que decidiste.

const FUENTE := preload("res://assets/ui/BoldPixels.ttf")

var _label: Label
var _salto := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(700, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", FUENTE)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_label.modulate.a = 0.0
	centro.add_child(_label)
	await _secuencia()

func _secuencia() -> void:
	await get_tree().create_timer(2.0).timeout
	if GameManager.flags.get("final_1", false):
		await _decir("El reloj no volvió a andar.")
		await _decir("Por primera vez, nadie repitió el día.")
		await _decir("Nadie sabe todavía qué viene después.")
	elif GameManager.flags.get("final_por_tiempo", false):
		await _decir("El reloj volvió a andar solo.")
		await _decir("Luis perdió otra vez la llave de la despensa.")
		await _decir("Nadie recordó nada.")
	else:
		await _decir("El reloj volvió a andar.")
		await _decir("Luis perdió la llave de la despensa.")
		await _decir("Nadie recordó nada.")
	if GameManager.flags.get("intro_quedarse", false):
		await _decir("Habías pedido quedarte. Ahora, al menos, sabés por qué.")
	await _decir("SIN REGISTRO", 4.0)
	await _decir("Gracias por jugar.", 3.0)
	get_tree().quit()

func _decir(texto: String, pausa: float = -1.0) -> void:
	_label.text = texto
	var t := create_tween()
	t.tween_property(_label, "modulate:a", 1.0, 1.2)
	await t.finished
	await _esperar(pausa if pausa > 0.0 else maxf(2.2, texto.length() * 0.07))
	t = create_tween()
	t.tween_property(_label, "modulate:a", 0.0, 0.8)
	await t.finished
	await get_tree().create_timer(0.5).timeout

func _esperar(segundos: float) -> void:
	_salto = false
	var t := 0.0
	while t < segundos and not _salto:
		await get_tree().process_frame
		t += get_process_delta_time()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		_salto = true
