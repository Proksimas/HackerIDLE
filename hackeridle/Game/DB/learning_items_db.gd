extends Node

const LEARNING_ITEMS_PATH = "res://Game/DB/learning_items_db.json"

var learning_items_db: Dictionary 

func _ready() -> void:
	pass
	#init_learning_items_db()


func init_learning_items_db():
	var items: Dictionary = Global.load_json(LEARNING_ITEMS_PATH)
	
	for item in items["learning_items"]:
		var dict_item = { "item_name": item["item_name"],
							"id": item["id"],
							"texture_path": item["texture_path"],
							"animation_path": item["animation_path"],
							"level": 1,
							"cost": item["cost"],
							"cost_factor": item["cost_factor"],
							"gain": item["gain"],
							"gain_factor":item["gain_factor"], 
							"formule_type":item["formule_type"],
							"level_ipk": 0, #"niveau" de l'imrvemet de la connaissance passive
							"level_ipc": 0 #'niveau de gain par click
							}
							
		if learning_items_db.has(item["item_name"]):
			push_warning("Item initialisation en double")
		
		else:
			learning_items_db[item["item_name"]] = dict_item
			#Player.learning_item_statut[item["item_name"]] = "locked"
	##le premier item doit etre en mode to_unlocked
	#Player.learning_item_statut[Player.learning_item_statut.keys()[0]] = "to_unlocked"
		#
		
func init_for_player():
	for item_name in learning_items_db:
		Player.learning_item_statut[item_name] = "locked"
		
	#le premier item doit etre en mode to_unlocked
	Player.learning_item_statut[Player.learning_item_statut.keys()[0]] = "to_unlocked"
	pass
		


func get_item_cara(item_name: String):
	if learning_items_db.has(item_name):
		return learning_items_db[item_name]
	else:
		push_error("L'item demandé n'existe pas")
