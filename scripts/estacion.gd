extends Node2D

# --- IDENTIFICACIÓN Y CONFIGURACIÓN ---
@export var id_estacion : int = 1
@export var tecla_activacion : String = "tecla_1"
@export var nombre_estacion : String = "Estación"
@export var color_base_estacion : Color = Color.GRAY

# --- PERSONALIZACIÓN DE TIEMPOS Y DISEÑO ---
@export var velocidad_coccion : float = 20.0
@export var tasa_enfriamiento : float = 10.0
@export var tiempo_max_quemado : float = 10.0 # Reducido un poco para más dificultad
@export var grosor_borde : float = 20.0       # Grosor para la Feria

signal plato_completado(id)

# --- VARIABLES DE ESTADO ---
var progreso : float = 0.0
var tiempo_actual_quemado : float = 0.0
var esta_siendo_usada : bool = false
var multiplicador_global : float = 1.0
var vibracion_forzada : bool = false
var timer_activo : bool = false 

# --- REFERENCIAS INTERNAS ---
@onready var barra = $ProgressBar
@onready var brazo = $Brazo
@onready var cuadrado_fondo = $ColorRect
@onready var label_nombre = $NombreLabel

var estilo_relleno : StyleBoxFlat

func _ready():
	if label_nombre: label_nombre.text = "[" + nombre_estacion + "]"
	if cuadrado_fondo: cuadrado_fondo.color = color_base_estacion
	
	estilo_relleno = StyleBoxFlat.new()
	barra.add_theme_stylebox_override("fill", estilo_relleno)
	
	if brazo:
		brazo.visible = false
		brazo.width = 12.0
		brazo.default_color = Color("8a2be2")
		brazo.clear_points()
		brazo.add_point(Vector2.ZERO)
		brazo.add_point(Vector2.ZERO)

func _process(delta):
	# --- 1. CONTROL DE PAUSA ---
	# Si el juego está pausado, escondemos el brazo y no procesamos nada
	if get_tree().paused:
		if brazo: brazo.visible = false
		return 

	# --- 2. LÓGICA DEL TEMPORIZADOR DE BORDE ---
	if timer_activo:
		queue_redraw()
		tiempo_actual_quemado += delta
		if tiempo_actual_quemado >= tiempo_max_quemado:
			estacion_quemada()
	else:
		tiempo_actual_quemado = 0
		queue_redraw()

	# --- 3. ACCIÓN DEL JUGADOR ---
	if Input.is_action_pressed(tecla_activacion):
		esta_siendo_usada = true
		progreso += delta * velocidad_coccion * multiplicador_global
		
		if vibracion_forzada:
			barra.position = Vector2(randf_range(-4, 4), randf_range(-4, 4))
		else:
			barra.position = Vector2.ZERO
		
		if brazo: actualizar_posicion_brazo()
		
		if progreso >= 100:
			progreso = 0
			timer_activo = false
			emit_signal("plato_completado", id_estacion)
	else:
		esta_siendo_usada = false
		progreso = max(0, progreso - delta * tasa_enfriamiento)
		barra.position = Vector2.ZERO
		
		# Escondemos el tentáculo si el jugador suelta la tecla
		if brazo: brazo.visible = false
	
	if barra:
		barra.value = progreso
		actualizar_color_barra()

func estacion_quemada():
	progreso = 0
	tiempo_actual_quemado = 0
	timer_activo = false 
	emit_signal("plato_completado", -1) 
	
	var tw = create_tween()
	tw.tween_property(cuadrado_fondo, "color", Color.BLACK, 0.05)
	tw.tween_property(cuadrado_fondo, "color", color_base_estacion, 0.1)

func actualizar_color_barra():
	if progreso < 35: estilo_relleno.bg_color = Color.RED
	elif progreso < 75: estilo_relleno.bg_color = Color.YELLOW
	else: estilo_relleno.bg_color = Color.GREEN

func actualizar_posicion_brazo():
	brazo.visible = true
	var cuerpo = get_parent().get_node_or_null("PulpoCuerpo")
	if cuerpo:
		var posicion_relativa = cuerpo.global_position - global_position
		brazo.set_point_position(1, posicion_relativa)

func _draw():
	if not timer_activo or cuadrado_fondo == null: return
	
	var rect_size = cuadrado_fondo.size
	var ratio = tiempo_actual_quemado / tiempo_max_quemado
	var color_borde = Color.GREEN.lerp(Color.RED, ratio)
	
	var p1 = Vector2.ZERO
	var p2 = Vector2(rect_size.x, 0)
	var p3 = Vector2(rect_size.x, rect_size.y)
	var p4 = Vector2(0, rect_size.y)
	
	var t = ratio * 4.0
	
	if t > 0: draw_line(p1, p1.lerp(p2, min(t, 1.0)), color_borde, grosor_borde)
	if t > 1: draw_line(p2, p2.lerp(p3, min(t - 1.0, 1.0)), color_borde, grosor_borde)
	if t > 2: draw_line(p3, p3.lerp(p4, min(t - 2.0, 1.0)), color_borde, grosor_borde)
	if t > 3: draw_line(p4, p4.lerp(p1, min(t - 3.0, 1.0)), color_borde, grosor_borde)
