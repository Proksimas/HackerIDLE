extends Node

@export var nb_of_event: int 

const EVENTS_DB_PATH = "res://Game/Events/events_DB.json"
const EVENT = preload("res://Game/Events/event.tres")
var events_pool: Dictionary = {} # event_id = Event: Resource
var events_pool_passed: Dictionary = {} # event_id = Event: Resource

func _ready() -> void:
	events_initialisation()

func events_initialisation():
	events_pool.clear()
	events_pool_passed.clear()
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
	
func get_random_event():
	var rand = randi_range(1, nb_of_event)
	var event = events_pool[rand]
	
	return event
	
	
