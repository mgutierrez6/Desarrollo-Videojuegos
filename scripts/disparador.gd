extends Area2D
# Cuando el jugador entra: piensa en voz alta (1 línea) y/o cambia el objetivo. Una sola vez.

@export var flags_requeridos: Array[String] = []
@export var flags_prohibidos: Array[String] = []
@export_multiline var pensamiento: String = ""
@export var objetivo: String = ""
@export var consejo: String = ""
@export var flag_visto: String = ""      # obligatorio: evita que se repita

func _ready() -> void:
	body_entered.connect(_on_body)

func _on_body(body: Node2D) -> void:
	if not (body is CharacterBody2D) or flag_visto == "":
		return
	if GameManager.flags.get(flag_visto, false):
		return
	for f in flags_requeridos:
		if not GameManager.flags.get(f, false):
			return
	for f in flags_prohibidos:
		if GameManager.flags.get(f, false):
			return
	GameManager.flags[flag_visto] = true
	if objetivo != "":
		GameManager.set_objetivo(objetivo)
	if consejo != "":
		Consejos.mostrar(flag_visto, consejo)
	if pensamiento != "" and Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo([pensamiento])
