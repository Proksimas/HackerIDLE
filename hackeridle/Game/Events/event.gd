extends Resource

class_name Event

#stat_click_mod = modifier sur le click. exemple:
#						xp_click_flat = point d'xp à chaque click
#						gold_gain_flat = gold gagné d'un coup
#						knowledge_gain_perc = le pourcentage d'argent qu'on gagne 
#											par rapport à la connaissance actuelle
#
#infamy

# Pour le SETUP
var event_titre_id: String
var event_description_id: String
var event_choice_1: Dictionary
var event_choice_2:  Dictionary
var event_id: int
# ################
var max_keys = 4
var min_keys = 1
var max_effect_weight = 30
var min_effect_weight= 10 
# le weight est le ratio de 1 unité de la variable pour 1 unité d’infam
# les valeurs en % devront avoir un /10 
var effects_cara = {
					"xp_click_flat":  {"freq":20,
								"weight": 8},
					"xp_click_perc":  {"freq":35,
								"weight": 20},
					"knowledge_click_bonus":  {"freq":35,
								"weight": 5},
					"knowledge_click_perc":  {"freq":55,
								"weight": 18},
					"perc_from_gold": {"freq":65,
								"weight": 5},
					"perc_from_knowledge": {"freq":65,
								"weight": 5},
					"perc_from_brain_xp": {"freq":75,
								"weight": 5},
					"hack_time_perc": {"freq":35,
								"weight": 10},
					"hack_gold_perc": {"freq":55,
								"weight": 10},
					"hack_cost_perc": {"freq":35,
								"weight": 10},
					"learning_items_cost_perc": {"freq":55,
								"weight": 10},
					"learning_items_knowledge_perc": {"freq":35,
								"weight": 10}
							}



func event_setup(_id, _choice_1_effects, _choice_2_effects) -> void:
	event_id = _id
	event_titre_id = "event_{id}_titre".format({"id": _id})
	event_description_id = "event_{id}_desc".format({"id": _id})
	event_choice_1["texte_id"] = "event_{id}_choix1".format({"id": _id})
	event_choice_2["texte_id"] = "event_{id}_choix2".format({"id": _id})
	create_effects()
	#event_choice_1["effects"] = _choice_1_effectscre
	#event_choice_2["effects"] = _choice_2_effects
	

func create_effects():
	"""On va créer les effets en prenant en compte la fréquence d'apparition
	et le poids de l'effet
	L'infamy correspond à la somme des effets, avec une variation de x%
	Si le choice 1 a un weight positif, le choice 2 doiten avoir un equivalent
	(avec legere variation) en négatif"""
	# on choisit les keys selon leurs fréquences
	var lst_choices_name = ["choice_a", "chocie_b"]
	for choice_name in lst_choices_name:
		var keys_chosen = get_keys()
		var effects = build_values(keys_chosen)
		
		match choice_name:
			"choice_a":
				event_choice_1["effects"] = effects
			_:
				event_choice_2["effects"] = effects

	
	
func get_keys():
	var effects_cara_keys = effects_cara.keys()
	effects_cara_keys.shuffle()
	var nb_events = randi_range(min_keys, max_keys)
	var keys = []
	for key_name in effects_cara_keys:
		var rand = randi_range(0, 100)
		if rand <= effects_cara[key_name]["freq"]:
			keys.append(key_name)
			if len(keys) >= nb_events:
				break
	if len(keys) < 1: # si pas de chance etqu'on a vraiment rien
		keys.append(effects_cara_keys[0])
	return keys

func build_values(keys: Array) -> Dictionary:
	"""on va créer les valeurs selon les poids des clées"""
	var effects: Dictionary = {}
	var points = 0
	#while points <= max_effect_weight:
	keys.shuffle()
	for key in  keys:

		var add: float = 0
		var weight:float = 0
		weight = effects_cara[key]["weight"]
		
		add = 0
		if key.begins_with('perc_'):
			add = snapped(randf_range(0, 1), 0.001)
				
		elif key.ends_with('_perc'):
			if key == "hack_gold_perc" or key == "hack_cost_perc" or\
			 key == "learning_items_cost_perc" or "learning_items_knowledge_perc":
				add = snapped(randf_range(-0.4, 0.4), 0.001)
			else:
				add = snapped(randf_range(0, 0.5), 0.001)
				
		elif key == "xp_click_flat":
			add = randi_range(0, 4)
		elif key == "knowledge_click_bonus":
			add = randi_range(0, 10)
		else:
			push_warning("key pa spris en compte")
			
		if points > max_effect_weight: #on limite le max. Les derniers elements auront 0
			add = 0
				#on diminue le add d'un pourcentage du weight actuel
		points += add * weight
		#print("key: %s   value: %s    points: %s" % [key, add, points])
		
		if effects.has(key):
			effects[key] += add
		elif !effects.has(key) and add == 0:
			effects.erase(key)
		else:
			effects[key] = add
			
	effects["infamy"] = floor(points)
	#print("effets: %s " % effects)
	#print("point: %s" % points)
			 
	return effects
