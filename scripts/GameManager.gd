extends Node

signal inventario_cambiado

var datos_items = {
	"Palo": {
		"nombre": "Palo",
		"textura": preload("res://assets/recolectables/palo.png"),
		"descripcion": "Un pedazo de madera."
	},
	"Pelota": {
		"nombre": "Pelota",
		"textura": preload("res://assets/recolectables/pelota3.png"),
		"descripcion": "Pelota azul."
	},
	"Palanca": {
		"nombre": "Palanca",
		"textura": preload("res://assets/recolectables/palanca.png"),
		"descripcion": "Un palo modificado para ser palanca."
	}
}

# Lista de nombres o IDs de los objetos recolectados
var inventario: Array = []

var item_seleccionado: String = ""
var flags: Dictionary = {}   # estado del mundo: "pozo_revisado", "puerta1_abierta", etc.

# Las claves van en ORDEN ALFABÉTICO: "A+B", nunca "B+A"
var recetas: Dictionary = {
	"Palo+Pelota": "Palanca",
	# "Cuerda+Iman": "Pescador magnetico",
}

func agregar_item(item_nombre: String):
	if not item_nombre in inventario:
		inventario.append(item_nombre)
		inventario_cambiado.emit()

func remover_item(item_nombre: String):
	if item_nombre in inventario:
		inventario.erase(item_nombre)
		if item_seleccionado == item_nombre:
			item_seleccionado = ""
		inventario_cambiado.emit()

func tiene_item(item_nombre: String) -> bool:
	return item_nombre in inventario

# Devuelve el nombre del ítem resultante, o "" si no hay receta
func combinar_items(a: String, b: String) -> String:
	var par = [a, b]
	par.sort()
	var clave = par[0] + "+" + par[1]
	if not recetas.has(clave):
		return ""
	var resultado: String = recetas[clave]
	remover_item(a)
	remover_item(b)
	agregar_item(resultado)
	return resultado
