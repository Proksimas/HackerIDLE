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
							"up_level": source["up_level"],
							"up_factor":source['up_factor'],
							"affectation": source["affectation"],
							"formule_type": source['formule_type'],
							"effects": source['effects'],
							"level": 0
							}
							
		if sources_db.has(source["source_name"]):
			push_error("Source initialisation en double")
		
		else:
			sources_db[source["source_name"]] = dict_source

func get_associated_source(hack_item_name: String):
	for i in range(sources_db.size()):
		if sources_db.values()[i]["affectation"] == hack_item_name:
			
			return get_source_cara(sources_db.values()[i]["source_name"])
	push_error("Problème de nom ou pas de source disponible pour %s" %\
				[hack_item_name])

func get_source_cara(source_name: String):
	if sources_db.has(source_name):
		return sources_db[source_name]
	else:
		push_error("La source demandée n'existe pas")
