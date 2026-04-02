extends Control

@onready var label_record = $RecordLabel

func _ready():
	# 1. Cargamos el récord desde el archivo user:// antes de mostrarlo
	GameManager.cargar_record()
	
	# 2. Mostramos el récord actualizado en el Label
	if label_record:
		label_record.text = "RÉCORD PERSONAL: " + str(GameManager.record_personal)

# Asegúrate de que este nombre sea EXACTAMENTE el mismo que configuraste 
# en la pestaña "Nodos -> Señales" del botón en el editor de Godot
func _on_button_pressed():
	# 3. Cambiamos a la cocina
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")
