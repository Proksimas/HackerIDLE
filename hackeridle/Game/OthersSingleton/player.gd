extends Node

signal earn_knowledge_point(point)
signal earn_hacking_point(point)
signal earn_gold(number)

var knowledge_point: float:
	set(value):
		knowledge_point = clamp(value, 0, INF)
		earn_knowledge_point.emit(knowledge_point)
		
var hacking_point: float:
	set(value):
		hacking_point =  clamp(value, 0, INF)
		earn_hacking_point.emit(hacking_point)
		
var gold: float:
	set(value):
		gold =  clamp(value, 0, INF)
		earn_gold.emit(gold)
		
var brain_level: int:
	set(value):
		brain_level = clamp(value,0, INF)
		
var learning_item_bought: Dictionary = {}
var hacking_item_bought: Dictionary = {}
													
func _ready() -> void:
	learning_item_bought.clear() # on vide le dictionnaire 
	

func add_learning_item(item_cara):

	var dict_to_store = {"item_name": item_cara['item_name'],
						"level": 1,
						"base_knowledge_point": 1}
						
	learning_item_bought[item_cara['item_name']] = dict_to_store
pass
	
##Gagne le nombre de level donné en paramètre
func learning_item_level_up(item_name: String, gain_of_level):
	learning_item_bought[item_name]["level"] += gain_of_level
	
	
func has_learning_item(item_name):
	if learning_item_bought.has(item_name):
		return true
	else:
		return false
		

func change_learning_property_value(item_name: String, property: String, value):
	if not has_learning_item(item_name):
		push_warning("L'item n'existe pas")
	learning_item_bought[item_name][property] = value


func add_hacking_item(item_cara):

	var dict_to_store = {"item_name": item_cara['item_name'],
						"level": 1,
						"base_gold_point": 1}
						
	hacking_item_bought[item_cara['item_name']] = dict_to_store

##Gagne le nombre de level donné en paramètre
func hacking_item_level_up(item_name: String, gain_of_level):
	hacking_item_bought[item_name]["level"] += gain_of_level

func has_hacking_item(item_name):
	if hacking_item_bought.has(item_name):
		return true
	else:
		return false
		
func change_hacking_property_value(item_name: String, property: String, value):
	if not has_hacking_item(item_name):
		push_warning("L'item n'existe pas")
	hacking_item_bought[item_name][property] = value
