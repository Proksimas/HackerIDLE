extends Node

var knowledge_point: float:
	set(value):
		return clamp(value, 0, INF)
		
var hacking_point: float:
	set(value):
		return clamp(value, 0, INF)
		
		
var learning_item_bought: Dictionary = {"item_name": {"level": 1,
													"knowledge_point_earned": 1} }
													
func _ready() -> void:
	learning_item_bought.clear() # on vide le dictionnaire 


func add_item(item_cara):
	if learning_item_bought.has(item_cara['item_name']):
		push_warning("L'item est déjà présent")
		return
	else:
		var dict_to_store = {"level": 1,
							"base_knowledge_point": 1} 
							
		learning_item_bought[item_cara['item_name']] = dict_to_store
	pass
	
##Gagne le nombre de level donné en paramètre
func item_level_up(item_name: String, gain_of_level):

	pass
