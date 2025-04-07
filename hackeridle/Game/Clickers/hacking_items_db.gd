extends Node
const HACKING_ITEMS_PATH = "res://Game/Clickers/hacking_items_db.tscn"


var learning_items_db: Dictionary 

func _ready() -> void:
	init_hacking_items_db()


func init_hacking_items_db():
	var items: Dictionary = Global.load_json(HACKING_ITEMS_PATH)
	
	for item in items["learning_items"]:
		var dict_item = { "item_name": item["item_name"],
							"texture_path": item["texture_path"],
							"animation_path": item["animation_path"],
							"base_knowledge_point": item["base_knowledge_point"]
							
							}
		if learning_items_db.has(item["item_name"]):
			push_error("Item initialisation en double")
		
		else:
			learning_items_db[item["item_name"]] = dict_item
		pass


func get_item_cara(item_name: String):
	if learning_items_db.has(item_name):
		return learning_items_db[item_name]
	else:
		push_error("L'item demandé n'existe pas")
