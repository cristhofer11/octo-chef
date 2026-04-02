extends Node

# --- CONFIGURACIÓN TÉCNICA ---
var grupos_estaciones = {
	0: [1, 2], # Corte
	1: [3, 4], # Sartenes
	2: [5, 6], # Ollas
	3: [7, 8]  # Montaje
}

# --- ESTADO DE LA PARTIDA ---
var meta_minima: int = 2
var ultimo_puntaje: int = 0
var record_personal: int = 0
var gano_ultima_partida: bool = false
var mensaje_final: String = ""

# --- LÓGICA DE LA COMANDA ---
var receta_actual: Array = []
var pasos_completados: Array = []
var nombre_plato_actual: String = ""
const NOMBRES_PLATOS = ["Ceviche Extremo", "Paila Sansana", "Guiso de Mar", "Asado de Pulpo", "Caldillo Loco"]

func _ready():
	cargar_record()

func generar_receta_aleatoria():
	receta_actual.clear()
	pasos_completados.clear()
	nombre_plato_actual = NOMBRES_PLATOS.pick_random()
	
	var grupos_pool = [0, 1, 2, 3]
	grupos_pool.shuffle()
	
	# Elegimos 3 estaciones de 3 grupos distintos para asegurar variedad
	for i in range(3):
		var id_grupo = grupos_pool[i]
		var estacion_id = grupos_estaciones[id_grupo].pick_random()
		receta_actual.append(estacion_id)

# --- PERSISTENCIA ---
const RUTA_GUARDADO = "user://save_game.cfg"

func guardar_record():
	var config = ConfigFile.new()
	config.set_value("Progreso", "record", record_personal)
	config.save(RUTA_GUARDADO)

func cargar_record():
	var config = ConfigFile.new()
	if config.load(RUTA_GUARDADO) == OK:
		record_personal = config.get_value("Progreso", "record", 0)
