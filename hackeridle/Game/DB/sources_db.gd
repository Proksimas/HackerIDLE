extends Node

const SOURCES_DB = "res://Game/DB/sources_db.json"


var sources_db: Dictionary 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_sources_db()
	pass # Replace with function body.


func init_sources_db():
	var sources: Dictionary = Global.load_json(SOURCES_DB)
	
	for source in sources["sources"]:
		var dict_source = { "source_name": source["source_name"],
							"texture_path": source["texture_path"],
							"cost": source["cost"],
							"cost_factor":source['cost_factor'],
							"salary": source['salary'],
							"salary_factor": source['salary_factor'],
							"affectation": source["affectation"],
							"formule_type": source['formule_type'],
							"effects": source['effects'],
							"level": 1
							}
							
		if sources_db.has(source["source_name"]):
			push_error("Source initialisation en double")
		
		else:
			sources_db[source["source_name"]] = dict_source
			Player.sources_item_statut[source["source_name"]] = "locked"
			
	#la première source doit etre en mode to_unlocked
	Player.hacking_item_statut[Player.hacking_item_statut.keys()[0]] = "to_unlocked"

func get_source_cara(source_name: String):
	if sources_db.has(source_name):
		return sources_db[source_name]
	else:
		push_error("La source demandée n'existe pas")
