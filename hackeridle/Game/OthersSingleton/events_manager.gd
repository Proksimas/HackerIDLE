extends Node

@export var nb_of_event: int 


const EVENT_UI = preload("res://Game/Events/event_ui.tscn")
const EVENTS_DB_PATH = "res://Game/Events/events_with_effects.json" #"res://Game/Events/events_DB.json"
const EVENT = preload("res://Game/Events/event.tres")


var events_pool: Dictionary = {} # Tous les events inti: event_id = Event: Resource
var next_events: Array # sera un array dde chiffres léatoires entre 0 et le nb d'events dans le pool

#func _ready() -> void:
	#events_initialisation()

func events_initialisation():
	events_pool.clear()
	
	var file = FileAccess.open(EVENTS_DB_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var events_data = JSON.parse_string(content)

	for event_data in events_data:
		var id = int(event_data["id"].trim_prefix("event_"))
		var new_event = EVENT.duplicate()
		new_event.event_setup(id, event_data["choix"][0]["effets"],
								event_data["choix"][1]["effets"])
		events_pool[id] = new_event
	
	next_events = create_unique_list(events_pool.size())

	
func get_random_event():
	var rand = randi_range(1, nb_of_event)
	if len(events_pool) < rand:
		push_error("Scenario out of range")
	var event = events_pool[rand]
	
	return event
	
func get_pseudo_random_evet():
	"""On prend le premier élement de la liste pseudo aléatoire en le supprimant"""
	return events_pool[next_events.pop_front()]
	
func create_unique_list(x: int) -> Array:
	var unique_list = []
	for i in range(x + 1):
		unique_list.append(i)
	unique_list.shuffle()
	return unique_list

func get_specific_scenario(index):
	return events_pool[index]
	
func create_event_ui():
	""" affiche un nouvel EVENT"""
	#var interface =  get_tree().get_root().get_node("Main/Interface")
	var new_event = EVENT_UI.instantiate()
	#if interface:
		#interface.event_container.add_child(new_event)
	#else:
		#push_error("Pas d'interface de trouvée")
	return new_event

func _save_data() -> Dictionary:
	"""Retourne un dictionnaire des variables importantes pour la sauvegarde et le chargement."""
	var dict = {"next_events": next_events}
	return dict

func _load_data(data):
	"""Manage les chargement des events"""
	#on reinitialise la db
	events_initialisation()
	# et IMPORTANT on force de reprendre les events passés
	next_events = data["next_events"]
