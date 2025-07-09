extends Node
const HACKING_ITEMS_PATH = "res://Game/DB/hacking_items_db.json"

var hacking_items_db: Dictionary 

func _ready() -> void:
	pass
	#init_hacking_items_db()


func init_hacking_items_db():
	var items: Dictionary = Global.load_json(HACKING_ITEMS_PATH)
	
	for item in items["hacking_items"]:
		var dict_item = { "item_name": item["item_name"],
							"texture_path": item["texture_path"],
							"cost": item["cost"],
							"cost_factor":item['cost_factor'],
							"gain": item['gain'],
							"gain_factor": item['gain_factor'],
							"delay": item["delay"],
							"formule_type": item['formule_type'],
							"level": 1
							}
							
		if hacking_items_db.has(item["item_name"]):
			break
			push_warning("Item initialisation en double")
		
		else:
			hacking_items_db[item["item_name"]] = dict_item
			#Player.hacking_item_statut[item["item_name"]] = "locked"
			#
	##le premier item doit etre en mode to_unlocked
	#Player.hacking_item_statut[Player.hacking_item_statut.keys()[0]] = "to_unlocked"
		#
func init_for_player():
	for item_name in hacking_items_db:
		Player.hacking_item_statut[item_name] = "locked"
		
	#le premier item doit etre en mode to_unlocked
	Player.hacking_item_statut[Player.hacking_item_statut.keys()[0]] = "to_unlocked"
	pass
		
func get_item_cara(item_name: String):
	if hacking_items_db.has(item_name):
		return hacking_items_db[item_name]
	else:
		push_error("L'item demandé n'existe pas")
