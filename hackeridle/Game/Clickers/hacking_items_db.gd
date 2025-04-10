extends Node
const HACKING_ITEMS_PATH = "res://Game/DB/hacking_items_db.json"

var hacking_items_db: Dictionary 

func _ready() -> void:
	init_hacking_items_db()


func init_hacking_items_db():
	var items: Dictionary = Global.load_json(HACKING_ITEMS_PATH)
	
	for item in items["hacking_items"]:
		var dict_item = { "item_name": item["item_name"],
							"texture_path": item["texture_path"],
							"base_gold_point": item["base_gold_point"],
							"base_time_delay": item["base_time_delay"],
							"level": 0
							
							}
		if hacking_items_db.has(item["item_name"]):
			push_error("Item initialisation en double")
		
		else:
			hacking_items_db[item["item_name"]] = dict_item
		pass


func get_item_cara(item_name: String):
	if hacking_items_db.has(item_name):
		return hacking_items_db[item_name]
	else:
		push_error("L'item demandé n'existe pas")
