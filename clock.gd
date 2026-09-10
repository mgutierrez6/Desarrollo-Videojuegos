extends Node2D

# Vinculamos las manecillas desde el editor
@onready var horas_sprite = $Hs
@onready var minutos_sprite = $Min

func _process(delta):
	# Obtener la hora actual del sistema
	var tiempo = Time.get_time_dict_from_system()
	var hora = tiempo["hour"]
	var minuto = tiempo["minute"]
	var segundo = tiempo["second"]
	
	# Convertir el tiempo a ángulos (en radianes)
	# Un círculo completo son 360 grados o TAU (2 * PI) radianes.
	
	# 60 segundos por vuelta
	var angulo_segundos = (segundo / 60.0) * TAU
	
	# 60 minutos por vuelta + el avance proporcional de los segundos
	var angulo_minutos = ((minuto + segundo / 60.0) / 60.0) * TAU
	
	# 12 horas por vuelta + el avance proporcional de los minutos
	var angulo_horas = (((hora % 12) + minuto / 60.0) / 12.0) * TAU
	
	# Aplicar la rotación a cada flecha estática en su posición
	minutos_sprite.rotation = angulo_minutos
	horas_sprite.rotation = angulo_horas
