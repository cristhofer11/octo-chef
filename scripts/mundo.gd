extends Node2D

var platos_servidos : int = 0
var tiempo_restante : float = 80.0
var juego_terminado : bool = false

# --- VARIABLES VISUALES DE FEEDBACK ---
var tiempo_verde_timer : float = 0.0
var tiempo_rojo_timer : float = 0.0

# --- REFERENCIAS A LA UI ---
@onready var label_puntos = $CanvasLayer/ContadorLabel
@onready var label_tiempo = $CanvasLayer/TiempoLabel
@onready var label_ticket = $CanvasLayer/TicketPanel/TicketLabel
@onready var capa_pausa = $CapaPausa
@onready var boton_menu = $CapaPausa/BotonMenu

# --- REFERENCIAS DE FINALIZACIÓN ---
@onready var capa_game_over = $CapaGameOver
@onready var boton_menu_final = $CapaGameOver/BotonMenuFinal
@onready var capa_victoria = $CapaVictoria
@onready var boton_menu_victoria = $CapaVictoria/BotonMenuVictoria

func _ready():
	randomize()
	if capa_pausa: capa_pausa.visible = false
	if capa_game_over: capa_game_over.visible = false
	if capa_victoria: capa_victoria.visible = false
	
	if boton_menu: boton_menu.pressed.connect(_on_boton_menu_pressed)
	if boton_menu_final: boton_menu_final.pressed.connect(_on_boton_menu_pressed)
	if boton_menu_victoria: boton_menu_victoria.pressed.connect(_on_boton_menu_pressed)
	
	GameManager.generar_receta_aleatoria()
	actualizar_ui()
	
	for nodo in get_children():
		if nodo.has_signal("plato_completado"):
			nodo.plato_completado.connect(_on_estacion_finalizada)

func _process(delta):
	if get_tree().paused or juego_terminado: return
	
	tiempo_restante -= delta
	gestionar_color_tiempo(delta)
	label_tiempo.text = "TIEMPO: " + str(int(tiempo_restante))
	
	if tiempo_restante <= 0:
		finalizar_partida()

	var manos_ocupadas = 0
	for nodo in get_children():
		if "esta_siendo_usada" in nodo and nodo.esta_siendo_usada:
			manos_ocupadas += 1
	
	var multi = 1.0
	var modo_caos = false
	
	if manos_ocupadas == 2: multi = 0.6
	elif manos_ocupadas >= 3:
		multi = 0.1
		modo_caos = true
		
	for nodo in get_children():
		if "multiplicador_global" in nodo:
			nodo.multiplicador_global = multi
			if "vibracion_forzada" in nodo: nodo.vibracion_forzada = modo_caos

func gestionar_color_tiempo(delta):
	if tiempo_rojo_timer > 0:
		tiempo_rojo_timer -= delta
		label_tiempo.add_theme_color_override("font_color", Color.RED)
	elif tiempo_verde_timer > 0:
		tiempo_verde_timer -= delta
		label_tiempo.add_theme_color_override("font_color", Color.GREEN)
	elif tiempo_restante < 20:
		label_tiempo.add_theme_color_override("font_color", Color.RED)
		label_tiempo.visible = int(tiempo_restante * 5) % 2 == 0
	else:
		label_tiempo.add_theme_color_override("font_color", Color.WHITE)
		label_tiempo.visible = true

func _on_estacion_finalizada(id_estacion: int):
	if id_estacion == -1:
		tiempo_restante -= 7.0
		tiempo_rojo_timer = 1.5
		actualizar_ui()
		return

	if id_estacion in GameManager.receta_actual and not id_estacion in GameManager.pasos_completados:
		GameManager.pasos_completados.append(id_estacion)
		actualizar_ui()
		if GameManager.pasos_completados.size() == GameManager.receta_actual.size():
			servir_plato_completo()
	else:
		tiempo_restante -= 5.0
		tiempo_rojo_timer = 1.5

func servir_plato_completo():
	platos_servidos += 1
	if platos_servidos > GameManager.meta_minima:
		tiempo_restante += randi_range(10, 25)
		tiempo_verde_timer = 1.5
	
	GameManager.generar_receta_aleatoria()
	actualizar_ui()

func actualizar_ui():
	if label_ticket == null: return
	
	var nombres_estaciones = {
		3: "Picadora 1", 4: "Picadora 2",
		1: "Sartenes 1", 2: "Sartenes 2",
		5: "Ollas 1", 6: "Ollas 2",
		7: "Emplatar 1", 8: "Emplatar 2"
	}
	
	var txt = GameManager.nombre_plato_actual.to_upper() + "\n"
	txt += "------------------------\nEstaciones:\n\n"
	for id in GameManager.receta_actual:
		var nombre = nombres_estaciones.get(id, "Estación " + str(id))
		txt += "\t" + ("[OK] " if id in GameManager.pasos_completados else "[ ] ") + nombre + "\n"
	label_ticket.text = txt

	for nodo in get_children():
		if "id_estacion" in nodo:
			if nodo.id_estacion in GameManager.receta_actual and not nodo.id_estacion in GameManager.pasos_completados:
				nodo.timer_activo = true
			else:
				nodo.timer_activo = false
				nodo.tiempo_actual_quemado = 0

	label_puntos.text = "PLATOS: " + str(platos_servidos) + " / " + str(GameManager.meta_minima)
	if platos_servidos >= GameManager.meta_minima:
		label_puntos.add_theme_color_override("font_color", Color.GOLD)

func finalizar_partida():
	juego_terminado = true
	get_tree().paused = true 
	
	# 1. Chequeamos si es un nuevo récord ANTES de actualizar el GameManager
	var es_nuevo_record : bool = platos_servidos > GameManager.record_personal
	
	if es_nuevo_record:
		GameManager.record_personal = platos_servidos
		GameManager.guardar_record()
	
	# 2. Preparamos el texto base de resultados
	var texto_res = "PUNTUACIÓN: " + str(platos_servidos) + " / " + str(GameManager.meta_minima)
	
	# 3. Mostrar Pantalla de Victoria
	if platos_servidos >= GameManager.meta_minima:
		if capa_victoria:
			capa_victoria.visible = true
			# Buscamos el Label de resultados en la capa (asegúrate que el nombre coincida)
			var label_vic = capa_victoria.get_node_or_null("ResultadoVictoria")
			if label_vic:
				var mensaje = texto_res
				if es_nuevo_record:
					mensaje += "\n\n¡NUEVO RÉCORD PERSONAL!"
					mensaje += "\nNUEVA MARCA: " + str(GameManager.record_personal)
				label_vic.text = mensaje
	
	# 4. Mostrar Pantalla de Derrota
	else:
		if capa_game_over:
			capa_game_over.visible = true
			var label_der = capa_game_over.get_node_or_null("ResultadoDerrota")
			if label_der:
				label_der.text = texto_res 

func _input(event):
	if event.is_action_pressed("ui_cancel") and not juego_terminado:
		toggle_pausa()

func toggle_pausa():
	get_tree().paused = !get_tree().paused
	if capa_pausa: capa_pausa.visible = get_tree().paused

func _on_boton_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu_inicio.tscn")
