extends CanvasLayer

@onready var panel: NinePatchRect = $panel
@onready var label: RichTextLabel = $panel/label

var visible_dialogo: bool = false
var paginas_dialogo: Array = []
var indice_pagina: int = 0
var tween_texto: Tween

func _ready() -> void:
	Global.caja_dialogo = self
	panel.hide()

func iniciar_dialogo(lista_textos: Array) -> void:
	paginas_dialogo = lista_textos
	indice_pagina = 0
	panel.show()
	visible_dialogo = true
	mostrar_pagina_actual()

func mostrar_pagina_actual() -> void:
	var texto_actual = paginas_dialogo[indice_pagina]
	label.text = texto_actual
	label.visible_characters = 0
	
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		
	tween_texto = create_tween()
	var tiempo = texto_actual.length() * 0.03
	tween_texto.tween_property(label, "visible_characters", texto_actual.length(), tiempo)

func avanzar_dialogo() -> void:
	# Si todavía está escribiendo la frase actual, la completa
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
		label.visible_characters = label.text.length()
		return

	# Si ya terminó de escribir, pasamos a la siguiente página
	indice_pagina += 1
	if indice_pagina < paginas_dialogo.size():
		mostrar_pagina_actual()
	else:
		ocultar_mensaje() # Se acabaron las páginas, cerramos

func ocultar_mensaje() -> void:
	if tween_texto and tween_texto.is_running():
		tween_texto.kill()
	panel.hide()
	visible_dialogo = false

func _unhandled_input(event: InputEvent) -> void:
	if visible_dialogo and event.is_action_pressed("interactuar"):
		avanzar_dialogo()
		get_viewport().set_input_as_handled()
