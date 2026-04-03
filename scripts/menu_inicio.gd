extends Control

@onready var label_record = $RecordLabel
@onready var capa_instrucciones = $CapaInstrucciones
@onready var boton_abrir = $Button2      # El botón que abre las instrucciones
@onready var boton_volver = $CapaInstrucciones/BotonVolver # El botón para cerrar

func _ready():
	# 1. Cargamos el récord
	GameManager.cargar_record()
	
	if label_record:
		label_record.text = "RÉCORD PERSONAL: " + str(GameManager.record_personal)
	
	# 2. ¡MUY IMPORTANTE!: Escondemos la capa al iniciar. 
	# Si se queda prendida en el editor, bloqueará los clics de "Jugar".
	if capa_instrucciones:
		capa_instrucciones.visible = false
	
	# 3. Conectamos los botones por código para que sea más seguro
	if boton_abrir:
		boton_abrir.pressed.connect(_on_button_2_pressed)
	
	if boton_volver:
		boton_volver.pressed.connect(_on_boton_volver_pressed)

# --- LÓGICA DE LAS INSTRUCCIONES ---

# Esta función se activa al tocar Button2
func _on_button_2_pressed():
	capa_instrucciones.visible = true

# Esta función oculta la capa para volver al menú principal
func _on_boton_volver_pressed():
	capa_instrucciones.visible = false

# --- LÓGICA DE INICIO DE JUEGO ---

func _on_button_pressed():
	# Cambiamos a la cocina
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")
