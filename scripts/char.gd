extends CharacterBody2D

# Velocidad de movimiento en píxeles por segundo
@export var speed: float = 90.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaccion = $Interaccion

func _physics_process(_delta: float) -> void:
	# Obtener la dirección de entrada (-1, 0, 1)
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
				interaccion.position = Vector2(11, 12)
				animated_sprite.play("right")
			else:
				interaccion.position = Vector2(-11, 12)
				animated_sprite.play("left")
		else:
			if direction.y > 0:
				interaccion.position = Vector2(0, 21.5)
				animated_sprite.play("down")
			else:
				interaccion.position = Vector2(0, 1.5)
				animated_sprite.play("up")
	else:
		# pausa la animacion en el cuadro actual
		animated_sprite.stop()
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		# buscamos que cosas estan en la zona
		var cuerpos_superpuestos = interaccion.get_overlapping_bodies()
		var areas_superpuestas = interaccion.get_overlapping_areas()
		
		# vemos si hay objeto o area interactuable
		for elemento in cuerpos_superpuestos + areas_superpuestas:
			if elemento.has_method("interactuar"):
				elemento.interactuar()
				break # solo con el primero que encuentre

func _on_camino_der_body_entered(body: Node2D) -> void:
	Global.punto_spawn = "desde_main"
	get_tree().change_scene_to_file("res://escenas/puente_bosque.tscn")


func _on_camino_izq_puente_body_entered(body: Node2D) -> void:
	Global.punto_spawn = "desde_puente"
	get_tree().change_scene_to_file("res://escenas/juego.scn")
