class_name EtapaDialogo
extends Resource

@export_group("Condiciones")
@export var flags_requeridos: Array[String] = []
@export var flags_prohibidos: Array[String] = []
@export var items_requeridos: Array[String] = []

@export_group("Qué dice")
@export_multiline var texto: Array[String] = []

@export_group("Qué pasa después")
@export var flags_a_activar: Array[String] = []
@export var item_a_dar: String = ""
@export var items_a_quitar: Array[String] = []
@export var objetivo_nuevo: String = ""

@export_group("Elección (opcional)")
@export var pregunta: String = ""
@export var opciones: Array[String] = []
@export var respuestas: Array[String] = []   # una por opción, mismo orden
@export var flag_eleccion: String = ""       # guarda flag_eleccion_0, _1, _2

@export_group("Animación")
@export var anim_reposo_despues: String = ""   # pose de reposo desde ahora (ej: "parado")
