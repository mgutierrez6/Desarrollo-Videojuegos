extends CharacterBody2D

# Velocidad de movimiento en píxeles por segundo
@export var speed: float = 90.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaccion = $Interaccion

func _physics_process(_delta: float) -> void:
	# SI LA CAJA DE DIÁLOGO ESTÁ ABIERTA, FRENAMOS AL PERSONAJE
	if Global.caja_dialogo and Global.caja_dialogo.visible_dialogo:
		velocity = Vector2.ZERO
		animated_sprite.stop()
		move_and_slide()
		return  # corta para que no lea los inputs de movimiento
		
	# obtener la dirección de entrada (-1, 0, 1)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Asignar velocidad
	velocity = direction * speed
	
	# Mover el personaje
	move_and_slide()
	
	# Gestionar animaciones y dirección del sprite
	update_animation(direction)

func update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		# Prioriza la animación horizontal si se mueve en diagonal
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				interaccion.position = Vector2(11, 11)
				animated_sprite.play("right")
			else:
				interaccion.position = Vector2(-11, 11)
				animated_sprite.play("left")
		else:
			if direction.y > 0:
				interaccion.position = Vector2(0, 17.5)
				animated_sprite.play("down")
			else:
				interaccion.position = Vector2(0, 5)
				animated_sprite.play("up")
	else:
		# pausa la animacion en el cuadro actual
		animated_sprite.stop()
		
func _unhandled_input(event: InputEvent) -> void:
	# Si la caja de diálogo ya está en pantalla, no hacer nada acá
	if Global.caja_dialogo and Global.caja_dialogo.visible_dialogo:
		return

	if event.is_action_pressed("interactuar"):
		var cuerpos_superpuestos = interaccion.get_overlapping_bodies()
		var areas_superpuestas = interaccion.get_overlapping_areas()
		
		for elemento in cuerpos_superpuestos + areas_superpuestas:
			var objetivo = elemento
			if not objetivo.has_method("interactuar") and objetivo.get_parent():
				objetivo = objetivo.get_parent()
			
			if objetivo.has_method("interactuar"):
				objetivo.interactuar()
				get_viewport().set_input_as_handled() # Consume la tecla E para que no se duplique
				break

func _on_camino_der_body_entered(body: Node2D) -> void:
	Global.punto_spawn = "desde_main"
	get_tree().change_scene_to_file("res://escenas/puente_bosque.tscn")


func _on_camino_izq_puente_body_entered(body: Node2D) -> void:
	Global.punto_spawn = "desde_puente"
	get_tree().change_scene_to_file("res://escenas/juego.scn")
