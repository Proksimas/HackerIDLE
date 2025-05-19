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
var learning_item_statut: Dictionary = {}
var hacking_item_bought: Dictionary = {}
var hacking_item_statut: Dictionary = {}
													
func _ready() -> void:
	learning_item_bought.clear() # on vide le dictionnaire 
	

func add_learning_item(item_cara:Dictionary):

	var dict_to_store = item_cara.duplicate()
	#on oublie de mettre le niveau à jour
	dict_to_store["level"] = 1

						
	learning_item_bought[item_cara['item_name']] = dict_to_store
	
		#comme on ajoute l'item, il est forcement en mode unlocked
	self.learning_item_statut[item_cara['item_name']] = "unlocked"
	
	#Il faut ensuite que l'item n +1 soit en mode to_unlocked
	var items_name = Player.learning_item_statut.keys()
	for item_name in Player.learning_item_statut:
		if item_name == item_cara["item_name"]: #alors le prochain doit etre en "ton_unlocked
			var pos = items_name.find(item_name)
			if items_name.size() > pos + 1:
				var next_item_name = items_name[pos + 1]
				Player.learning_item_statut[next_item_name] = "to_unlocked"
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


func add_hacking_item(item_cara: Dictionary):

	var dict_to_store = item_cara.duplicate()
	#dict_to_store['level'] = 1

	hacking_item_bought[item_cara['item_name']] = dict_to_store

	#comme on ajoute l'item, il est forcement en mode unlocked
	self.hacking_item_statut[item_cara['item_name']] = "unlocked"
	
	#Il faut ensuite que l'item n +1 soit en mode to_unlocked
	var items_name = Player.hacking_item_statut.keys()
	for item_name in Player.hacking_item_statut:
		if item_name == item_cara["item_name"]: #alors le prochain doit etre en "ton_unlocked
			var pos = items_name.find(item_name)
			if items_name.size() > pos + 1:
				var next_item_name = items_name[pos + 1]
				Player.hacking_item_statut[next_item_name] = "to_unlocked"
		

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


func _save_data():
	return {"gold": self.gold,
			"knowledge_point": self.knowledge_point,
			"hacking_point": self.hacking_point
			}
