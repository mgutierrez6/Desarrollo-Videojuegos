extends Node2D

# Recorrido de la Test Room:
# Vecina -> Cuaderno (clave) -> Computadora -> Vecina da el Imán
# -> Palo + Cinta + Imán = Palo magnético -> Agujero (Llave) -> Puerta -> Elección -> Pueblo

func _ready() -> void:
	if GameManager.objetivo_actual == "":
		GameManager.set_objetivo("Lograr salir de la casa\nHablar con la chica")

	# Cuaderno: si ya hablaste con la vecina, te manda a la computadora
	$libro.inspeccionado.connect(_on_cuaderno_inspeccionado)

	# Computadora: al abrirla, volver a hablar con la vecina
	$PC.desbloqueado.connect(func(): GameManager.set_objetivo("Volver a hablar con la chica"))

	# Agujero: pistas según lo que tengas, y la llave al resolverlo
	$Agujero.sin_item.connect(_on_agujero_sin_item)
	$Agujero.item_incorrecto.connect(_on_agujero_sin_item)
	$Agujero.desbloqueado.connect(_on_agujero_desbloqueado)

func _on_cuaderno_inspeccionado() -> void:
	if GameManager.flags.get("vecina_hablada", false) and not GameManager.flags.get("compu_abierta", false):
		GameManager.set_objetivo("Usar la clave en la computadora")

func _on_agujero_sin_item() -> void:
	if GameManager.flags.get("vecina_dio_iman", false):
		GameManager.set_objetivo("Armar algo largo con el imán en la punta")

func _on_agujero_desbloqueado() -> void:
	GameManager.agregar_item("Llave")
	GameManager.set_objetivo("Abrir la puerta con la llave")

# ---------- Puerta: usa la llave y pregunta si salir ----------
func _preguntar_salir(pregunta: String) -> void:
	var i = await EleccionUi.elegir(pregunta, ["Salir", "Quedarme"])
	if i == 0:
		Global.punto_spawn = "desde_casa1"
		GameManager.set_objetivo("Explorar el pueblo")
		get_tree().change_scene_to_file("res://escenas/juego.scn")

func _on_puerta_desbloqueado() -> void:
	_preguntar_salir("Se abrió la puerta. ¿Salir de la casa?")

func _on_puerta_ya_resuelto() -> void:
	_preguntar_salir("¿Salir de la casa?")
