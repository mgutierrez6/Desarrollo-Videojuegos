extends Area2D
# Caja de los registros: candado (llave) -> teclado (código) -> registros.

signal abierta

@export var item_llave := "Llave de la caja"
@export var codigo := "419"
@export var flag_candado := "caja_desbloqueada"
@export var flag_abierta := "caja_abierta"
@export var imagen: Texture2D
@export_multiline var txt_candado := "Una caja con candado y un teclado."
@export_multiline var txt_llave := "El candado cede."
@export_multiline var registro := "REGISTRO DEL PUEBLO. Año 2. El aislado detuvo el reloj para que nadie repitiera el día. El pueblo quedó trabado en el mismo día. El Sistema reinició la jornada y cerró la escalera."
@export var objetivo_final := "Salir de la casa"

var _usando := false

func hay_algo_para_hacer() -> bool:
	return not GameManager.flags.get(flag_abierta, false)

func _decir(lineas: Array) -> void:
	if Global.caja_dialogo:
		Global.caja_dialogo.iniciar_dialogo(lineas)
		await Global.caja_dialogo.dialogo_terminado

func interactuar() -> void:
	if _usando:
		return
	_usando = true
	await _interactuar()
	_usando = false

func _interactuar() -> void:
	if GameManager.flags.get(flag_abierta, false):
		InspeccionUI.mostrar(imagen, registro)
		return
	if not GameManager.flags.get(flag_candado, false):
		if GameManager.item_seleccionado == item_llave:
			GameManager.remover_item(item_llave)
			GameManager.flags[flag_candado] = true
			await _decir([txt_llave])
		else:
			await _decir([txt_candado])
			return
	var ok = await KeypadUi.abrir(codigo)
	if ok:
		GameManager.flags[flag_abierta] = true
		GameManager.set_objetivo(objetivo_final, "aislado")
		abierta.emit()
		InspeccionUI.mostrar(imagen, registro)
