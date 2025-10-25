extends Node

@export var nb_of_event: int # S'assurer que 
@export var min_wait_time: int = 420
@export var max_wait_time: int = 540


@onready var timer_event: Timer = %TimerEvent

const EVENT_UI = preload("res://Game/Events/event_ui.tscn")
#const EVENTS_DB_PATH = "res://Game/Events/events_with_infame.json" #"res://Game/Events/events_DB.json"
const EVENT = preload("res://Game/Events/event.tres")

var malus_effects = ["infamy","hack_time_perc","learning_items_cost_perc",
					"hack_cost_perc"]
					
 # Comprend les events deja PASSE Tous les events inti: event_id = Event: Resource
var events_passed_pool: Dictionary = {}
var next_events: Array # sera un array dde chiffres léatoires entre 0 et le nb d'events dans le pool
var malus_and_gain_multi: Dictionary = {}  #{source_du_mod: value }

# tableau de multiplicateur du temps d'attente des events, directement en %
# 10 = + 10%, - 10 = -10%
var wait_time_modificators: Dictionary = {}   # {source_du_mod: value }

func events_initialisation():
	events_passed_pool.clear()
	next_events.clear()
	next_events = create_unique_list(nb_of_event)

func create_unique_list(x: int) -> Array:
	"""On initialise les futurs events, pour s'assurer que nous ayons pas de doublons.
	On va piocher dans cette liste à chaque fois le premier élement"""
	var unique_list = []
	for i in range(x):
		unique_list.append(i)
	unique_list.shuffle()
	return unique_list

func launch_timer():
	"""Lance le timer d'attente entre 2 évents"""
	var nbr =  randi_range(min_wait_time, max_wait_time) 
	var multiplicators: float = 0
	for mult in wait_time_modificators.values():
		multiplicators += mult
	if multiplicators != 0:
		nbr = nbr * (1 + multiplicators/100)
	timer_event.paused = false
	timer_event.start(nbr)
	
	
func create_event(scenario_specific: int = -1):
	"""On créé l'event complet."""
	var event = Event.new()
	event.event_setup(next_events[scenario_specific])
	#On le supprimer de la liste et on le met dans l'events_pool si
	# ce n'est pas un event spécifique
	if scenario_specific <= 0:
		events_passed_pool[next_events.pop_front()] = event

	return event
	
func create_event_and_ui(scenario_specific: int = -1):
	""" affiche un nouvel EVENT dans l'event_ui, en créant du coup l'event"""
	var event_ui = EVENT_UI.instantiate()
	var interface = Global.get_interface()
	var event: Event = create_event(scenario_specific)
	interface.main_tab.add_child(event_ui)

	event_ui.event_ui_setup(event)
	timer_event.paused = true
	event_ui.s_event_finished.connect(_on_s_event_finished.bind(event_ui))
	
func _on_timer_event_timeout() -> void:
	"""Quand timeout, on instaure un nouvel event"""
	create_event_and_ui()
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
	
	#ATTENTION pour le moment les events_passed_pool sont enregistrés de manière encodés
	# faudra faire un enregistrement des valeurs de l'évent si besoin 
	var dict = {"next_events": next_events,
				"events_passed_pool": events_passed_pool,
				"time_event_left": timer_event.time_left,
				"malus_and_gain_multi": malus_and_gain_multi}
	return dict

func _load_data(data):
	"""Manage les chargement des events"""
	#on reinitialise la db
	events_initialisation()
	# et IMPORTANT on force de reprendre les events passés
	next_events = data["next_events"]
	events_passed_pool = data["events_passed_pool"]
	timer_event.wait_time = data["time_event_left"]
	malus_and_gain_multi = data["malus_and_gain_multi"]
	timer_event.start(data["time_event_left"])
