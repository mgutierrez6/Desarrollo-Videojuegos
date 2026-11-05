extends AudioStreamPlayer2D
# Golpes que vienen de abajo, siempre con el mismo ritmo. El ritmo ES el código.

@export var grupos: Array[int] = [3, 1, 4]       # golpes por grupo; el código es "314"
@export var primer_golpe := 25.0
@export var entre_golpes := 0.4
@export var entre_grupos := 1.4
@export var pausa_ciclo := 9.0
@export var distancia_audible := 450.0
@export var flag_detener := "aislado_conocido"
@export var mostrar_toc := true
@export_multiline var pensamiento := "¿Qué fue eso?"
@export var objetivo_aislado := "Descubrir quién golpea"

func _ready() -> void:
	await get_tree().create_timer(primer_golpe).timeout
	while is_inside_tree() and not GameManager.flags.get(flag_detener, false):
		if not Global.jugador_bloqueado():
			await _ciclo()
		await get_tree().create_timer(pausa_ciclo).timeout

func _ciclo() -> void:
	for g in grupos.size():
		for i in range(grupos[g]):
			_golpe()
			await get_tree().create_timer(entre_golpes).timeout
		await get_tree().create_timer(entre_grupos).timeout
	if not GameManager.flags.get("golpe_oido", false):
		GameManager.flags["golpe_oido"] = true
		GameManager.set_objetivo(objetivo_aislado, "aislado")
		if pensamiento != "" and Global.caja_dialogo:
			Global.caja_dialogo.iniciar_dialogo([pensamiento])

func _golpe() -> void:
	if stream:
		play()
	var j = get_tree().current_scene.find_child("Jugador", true, false)
	if j == null or global_position.distance_to(j.global_position) > distancia_audible:
		return
	var cam := get_viewport().get_camera_2d()
	if cam:
		var t := create_tween()
		t.tween_property(cam, "offset", Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)), 0.03)
		t.tween_property(cam, "offset", Vector2.ZERO, 0.05)
	if mostrar_toc:
		_toc()

func _toc() -> void:
	var l := Label.new()
	l.text = "toc"
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.position = Vector2(-8, -6)
	l.z_index = 30
	add_child(l)
	var t := create_tween()
	t.tween_property(l, "position:y", -16.0, 0.5)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)
