extends Node

const LEARNING_ITEMS_PATH = "res://Game/DB/learning_items_db.json"

var learning_items_db: Dictionary 

func _ready() -> void:
	init_learning_items_db()


func init_learning_items_db():
	var items: Dictionary = Global.load_json(LEARNING_ITEMS_PATH)
	
	for item in items["learning_items"]:
		var dict_item = { "item_name": item["item_name"],
							"texture_path": item["texture_path"]
							
							}
		if learning_items_db.has(item["item_name"]):
			push_error("Item initialisation en double")
		
		else:
			learning_items_db[item["item_name"]] = dict_item
		pass
