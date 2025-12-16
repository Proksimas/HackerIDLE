extends Panel

@onready var logs_container: VBoxContainer = %LogsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer

# Nombre max de logs stockés avant suppression du plus ancien
@export var max_logs: int = 50

# Assurez-vous que LOGS_LABEL est bien le RichTextLabel avec la fonction log_event
const LOGS_LABEL = preload("res://Game/Interface/Stacks/logs_label.tscn")

# --- NOUVEAUX EXEMPLES DE DONNÉES AVEC TABLEAU D'EFFETS ---
var event_multi_shield_dot = {
	"caster_name": "Invocateur",
	"target_names": ["Tank", "Soigneur"],
	"effects": [
		{"damage": 10, "type": "Shield"}, # Perte de bouclier (violet)
		{"damage": 5, "type": "DoT"}      # Poison (vert)
	]
}
var event_double_hp = {
	"caster_name": "Berserker",
	"target_names": ["Guerrier"],
	"effects": [
		{"damage": 20, "type": "HP"},     # Coup normal (rouge)
		{"damage": 5, "type": "HP"}       # Saignement (rouge)
	]
}

#func _ready() -> void:
	## Test
	#add_log(event_multi_shield_dot)
	#add_log(event_double_hp)
	#for i in range(max_logs):
		#add_log(event_multi_shield_dot)
		
func add_log(event: Dictionary):
	# 1. Gestion de la limite de logs (Suppression du plus ancien)
	if logs_container.get_child_count() >= max_logs:
		var oldest_log = logs_container.get_child(0)
		oldest_log.queue_free()

	# 2. Création et ajout du nouveau log
	var new_log = LOGS_LABEL.instantiate()
	logs_container.add_child(new_log)
	
	# Appel de la fonction de formatage sur le nouveau RichTextLabel
	new_log.log_event(event) # Le dictionnaire "event" contient maintenant le tableau "effects"
	scroll_container.call_deferred("set_v_scroll", get_max_v_scroll())
	
## Fonction d'aide pour obtenir la position de défilement maximale
func get_max_v_scroll() -> int:
	return scroll_container.get_v_scroll_bar().max_value
	
	
func _clear():
	for elmt in logs_container.get_children():
		elmt.queue_free()
