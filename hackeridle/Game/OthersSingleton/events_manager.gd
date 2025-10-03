extends Node

@export var nb_of_event: int 
@export var min_wait_time: int = 420
@export var max_wait_time: int = 540


@onready var timer_event: Timer = %TimerEvent

const EVENT_UI = preload("res://Game/Events/event_ui.tscn")
const EVENTS_DB_PATH = "res://Game/Events/events_with_infame.json" #"res://Game/Events/events_DB.json"
const EVENT = preload("res://Game/Events/event.tres")

var malus_effects = ["infamy","hack_time_perc","learning_items_cost_perc",
					"hack_cost_perc"]
var events_pool: Dictionary = {} # Tous les events inti: event_id = Event: Resource
var next_events: Array # sera un array dde chiffres léatoires entre 0 et le nb d'events dans le pool
# tableau de multiplicateur du temps d'attente des events, directement en %
# 10 = + 10%, - 10 = -10%
var wait_time_modificators: Dictionary = {}   # {source_du_mod: value }


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
	
func launch_timer():
	var nbr =  randi_range(min_wait_time, max_wait_time) 
	var multiplicators: float = 0
	for mult in wait_time_modificators.values():
		multiplicators += mult
	if multiplicators != 0:
		nbr = nbr * (1 + multiplicators/100)
	timer_event.paused = false
	timer_event.start(nbr)

	
func create_event_ui(scenario_specific: int = -1):
	""" affiche un nouvel EVENT"""
	var event_ui = EVENT_UI.instantiate()
	var interface = Global.get_interface()
	
	interface.main_tab.add_child(event_ui)
	event_ui.event_ui_setup(scenario_specific)
	timer_event.paused = true
	event_ui.s_event_finished.connect(_on_s_event_finished.bind(event_ui))
	
func _on_timer_event_timeout() -> void:
	"""Quand timeout, on instaure un nouvel event"""
	create_event_ui()
	pass # Replace with function body.
	
	
func _on_s_event_finished(_event_ui):
	"""L'event est fini. On le supprime et on relance le timer"""

	_event_ui.s_event_finished.disconnect(_on_s_event_finished)
	_event_ui.hide()
	_event_ui.queue_free()
	launch_timer()
	
	var interface = Global.get_interface()
	interface.app_button_pressed("learning")
	#if interface.jail.is_in_jail:
		

func _save_data() -> Dictionary:
	"""Retourne un dictionnaire des variables importantes pour la sauvegarde et le chargement."""
	var dict = {"next_events": next_events,
				"time_event_left": timer_event.time_left}
	return dict

func _load_data(data):
	"""Manage les chargement des events"""
	#on reinitialise la db
	events_initialisation()
	# et IMPORTANT on force de reprendre les events passés
	next_events = data["next_events"]
	timer_event.wait_time = data["time_event_left"]
	timer_event.start(data["time_event_left"])
