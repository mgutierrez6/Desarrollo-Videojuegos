extends CharacterBody2D

# Velocidad de movimiento en píxeles por segundo
@export var speed: float = 70.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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
				animated_sprite.play("right")
			else:
				animated_sprite.play("left")
		else:
			if direction.y > 0:
				animated_sprite.play("down")
			else:
				animated_sprite.play("up")
	else:
		# Al detenerse, pausa la animación en el cuadro actual
		animated_sprite.stop()

func _on_camino_der_body_entered(body: Node2D) -> void:
	get_tree().change_scene_to_file("res://escenas/puente_bosque.tscn")
