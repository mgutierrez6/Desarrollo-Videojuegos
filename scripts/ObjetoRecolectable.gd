extends Area2D

# Nombre exacto que coincide con la clave en GameManager.datos_items
@export var nombre_item: String = "Palo" 

var jugador_cerca: bool = false

func _on_body_entered(body):
	if body.is_in_group("jugador") or body.name == "Player":
		jugador_cerca = true

func _on_body_exited(body):
	if body.is_in_group("jugador") or body.name == "Player":
		jugador_cerca = false
	
func _ready():
	if GameManager.flags.get(_id(), false):
		queue_free()   # ya lo recogí antes
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _id() -> String:
	return "recogido_" + str(get_path())

func _unhandled_input(event):
	if jugador_cerca and event.is_action_pressed("interactuar"):
		if Global.jugador_bloqueado():
			return
		recolectar()
		get_viewport().set_input_as_handled()

func recolectar():
	GameManager.agregar_item(nombre_item)
	GameManager.flags[_id()] = true
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(["Recogiste: " + GameManager.datos_items[nombre_item]["nombre"]])
	queue_free()
