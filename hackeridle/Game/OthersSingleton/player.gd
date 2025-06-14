extends Node

signal earn_knowledge_point(point)
signal earn_hacking_point(point)
signal earn_gold(number)
signal earn_brain_xp(number)
signal earn_sp(number)
signal earn_brain_level(number)
signal s_brain_clicked(brain_xp, knowledge)

#region variables clampées
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
		
var brain_xp: int:
	set(value):	
		if _check_level_up():
			brain_xp = clamp(value - brain_xp, 0, INF)
		else:
			brain_xp = clamp(value, 0, INF)
		earn_brain_xp.emit(brain_xp)
		
var skill_point: int:
	set(value):
		skill_point = clamp(value, 0, INF)
		earn_sp.emit(skill_point)
		
var brain_level: int = 1:
	set(value):
		brain_level = clamp(value, 0, INF)
		earn_brain_level.emit(brain_level)
#endregion

var brain_xp_next: int = 0
var base_xp: int = 200
var xp_factor: float = 1.75

var learning_item_bought: Dictionary = {}
var learning_item_statut: Dictionary = {}
var hacking_item_bought: Dictionary = {}
var hacking_item_statut: Dictionary = {}
var sources_item_bought: Dictionary = {}

var skills_owned = {"active" : [],
					"passive": [] }
													
func _ready() -> void:
	learning_item_bought.clear() # on vide le dictionnaire 
	brain_xp_next = get_brain_xp(brain_level -1)
	
#region brain level
func _check_level_up():
	if brain_xp >= brain_xp_next:
		level_up()
		return true
	else: 
		return false
		
func level_up():
	#brain_xp -= brain_xp_next
	skill_point += 1
	brain_level += 1
	brain_xp_next =  get_brain_xp(brain_level - 1) 


func get_brain_xp(level_asked):
	# Base * pow(FacteurDeCroissance, level - 1)
	return round(base_xp * pow(xp_factor, level_asked))
	
#endregion

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
		
func add_source(source_cara: Dictionary):
	var dict_to_store = source_cara.duplicate()
	sources_item_bought[source_cara['source_name']] = dict_to_store

	pass

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

func get_associated_source(hack_item_name: String):
	for i in range(sources_item_bought.size()):
		if sources_item_bought.values()[i]["affectation"] == hack_item_name:
			return get_source_cara(sources_item_bought.values()[i]["source_name"])

func get_source_cara(source_name: String):
	if sources_item_bought.has(source_name):
		return sources_item_bought[source_name]
	else:
		push_error("La source demandée n'existe pas")
		
		
func brain_clicked():
	"""Le cerveau a été cliqué, on calcul les gains associés"""
	var brain_xp_to_gain = 1
	var knowledge_point_to_gain = 1
	
	Player.brain_xp += brain_xp_to_gain
	Player.knowledge_point += knowledge_point_to_gain
	s_brain_clicked.emit(knowledge_point_to_gain, brain_xp_to_gain )
	

func _save_data():
	return Global.get_serialisable_vars(self)
	#return {"gold": self.gold,
			#"knowledge_point": self.knowledge_point,
			#"hacking_point": self.hacking_point,
			#"learning_item_bought": self.learning_item_bought,
			#"learning_item_statut": self.learning_item_statut,
			#"hacking_item_bought": self.hacking_item_bought,
			#"hacking_item_statut": self.hacking_item_statut
			#}
