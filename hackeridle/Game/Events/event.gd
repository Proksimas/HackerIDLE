extends Resource

class_name Event

#stat_click_mod = modifier sur le click. exemple:
#						xp_click_bonus = point d'xp à chaque click
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
const MIN_KEYS = 1
const MAX_KEYS = 4
const MAX_EFFECT_WEIGHT = 30
const MIN_EFFECT_WEIGHT = 10
const MALUS_DECREASE_INFAMY = -0.8 # le maluse du ratio pour baisser l'infamy par rappot au poids
# le weight est le ratio de 1 unité de la variable pour 1 unité d’infam
# les valeurs en % devront avoir un /10 
# NOUVEAU DICTIONNAIRE OPTIMISÉ (avec les paramètres pour build_values)
# 'infamy_logic' peut être: "default", "inverted_time", "inverted_cost", "mixed"
var effects_cara = {
	# --- Effets de base/pourcentage purs (Logique Fusionnée 'default') ---

	"xp_click_base":        {"freq": 20, "weight": 8, "min_val": 0, "max_val": 4, "type": "int", "infamy_logic": "default"},
	"knowledge_click_base": {"freq": 35, "weight": 5, "min_val": 0, "max_val": 10, "type": "int", "infamy_logic": "default"},
	
	"xp_click_perc":        {"freq": 35, "weight": 20, "min_val": 0.0, "max_val": 0.5, "type": "float", "infamy_logic": "default"},
	"knowledge_click_perc": {"freq": 55, "weight": 30, "min_val": 0.0, "max_val": 0.5, "type": "float", "infamy_logic": "default"},
	
 
	"perc_from_gold":       {"freq": 65, "weight": 5, "min_val": 0.1, "max_val": 0.8, "type": "float", "infamy_logic": "default"},
	"perc_from_knowledge":  {"freq": 65, "weight": 5, "min_val": 0.1, "max_val": 0.8, "type": "float", "infamy_logic": "default"},
	"perc_from_brain_xp":   {"freq": 75, "weight": 5, "min_val": 0.1, "max_val": 0.8, "type": "float", "infamy_logic": "default"},

	"hack_gold_perc":                 {"freq": 55, "weight": 20, "min_val": -0.4, "max_val": 0.4, "type": "float", "infamy_logic": "default"},
	"learning_items_knowledge_perc":  {"freq": 35, "weight": 20, "min_val": -0.4, "max_val": 0.4, "type": "float", "infamy_logic": "default"},

	"hack_time_perc":               {"freq": 35, "weight": 30, "min_val": -0.4, "max_val": 0.4, "type": "float", "infamy_logic": "inverted_benefit"},
	"hack_cost_perc":               {"freq": 35, "weight": 20, "min_val": -0.4, "max_val": 0.4, "type": "float", "infamy_logic": "inverted_benefit"},
	"learning_items_cost_perc":     {"freq": 55, "weight": 20, "min_val": -0.4, "max_val": 0.4, "type": "float", "infamy_logic": "inverted_benefit"}
}
	
func event_setup(_id: int) -> void:
	"""On setup l'event en traduisant ses informations basiques. Puis on appelle 
	la fonction de création des effets"""
	event_id = _id
	event_titre_id = "event_{id}_titre".format({"id": _id})
	event_description_id = "event_{id}_desc".format({"id": _id})
	event_choice_1["texte_id"] = "event_{id}_choix1".format({"id": _id})
	event_choice_2["texte_id"] = "event_{id}_choix2".format({"id": _id})
	create_effects()

	

func create_effects():
	"""On va créer les effets en prenant en compte la fréquence d'apparition
	et le poids de l'effet
	L'infamy correspond à la somme des effets, avec une variation de x%
	Si le choice 1 a un weight positif, le choice 2 doiten avoir un equivalent
	(avec legere variation) en négatif"""
	# on choisit les keys selon leurs fréquences
	var lst_choices_name = ["choice_a", "chocie_b"]
	for choice_name in lst_choices_name:

		var keys_chosen = get_keys(MIN_KEYS, MAX_KEYS)
		var effects = build_values(keys_chosen,MIN_EFFECT_WEIGHT, MAX_EFFECT_WEIGHT, MALUS_DECREASE_INFAMY)
		
		match choice_name:
			"choice_a":
				event_choice_1["effects"] = effects
			_:
				event_choice_2["effects"] = effects

func get_keys(min_keys: int, max_keys: int) -> Array:
	var selected_keys = []
	
	var nb_events_target = randi_range(min_keys, max_keys)
	var all_keys = effects_cara.keys()
	all_keys.shuffle()
	for key_name in all_keys:
		if selected_keys.size() >= nb_events_target:
			break
		var frequency = effects_cara[key_name].freq
		if randi_range(1, 100) <= frequency:
			selected_keys.append(key_name)
	if selected_keys.is_empty():
		selected_keys.append(all_keys[0])
	return selected_keys
	# NOTE: Le dictionnaire 'effects_cara' doit être celui optimisé avec les champs min_val, max_val, type et infamy_logic.
# max_effect_weight est la limite supérieure positive de l'infamie.
# min_effect_weight est désormais interprété comme le COMPTE MINIMUM d'effets dans le résultat.

func build_values(keys: Array, min_effect_weight: int, max_effect_weight: float, malus_decrase_infamy: float) -> Dictionary:
	# Renommage interne du paramètre pour la clarté :
	var min_effects_count: int = min_effect_weight
	
	var effects: Dictionary = {}
	var points: float = 0.0 # Peut être négatif/nul
	
	keys.shuffle()
	var keys_with_zero_value: Array = []
 
	for key in keys:
		var config = effects_cara.get(key)
		
		if config == null: continue

		var add: float = 0.0
		var weight: float = config.weight
		var coef: float = 1.0
		
		# 1. Calcul de la valeur aléatoire (add)
		var min_val = config.min_val
		var max_val = config.max_val
		
		if config.type == "int":
			add = float(randi_range(int(min_val), int(max_val)))
		else:
			add = snapped(randf_range(min_val, max_val), 0.001)

		# 2. Détermination du Coefficient d'Infamie (coef)
		match config.infamy_logic:
			"default":
				# Logique pour GAINS (add >= 0 est Bénéfice): Bénéfice -> Infamie Totale / Préjudice -> Anti-Infamie Réduite
				coef = 1.0 if add >= 0.0 else malus_decrase_infamy

			"inverted_benefit":
				# Logique pour COUTS (add < 0 est Bénéfice): Préjudice -> Anti-Infamie Réduite / Bénéfice -> Infamie Totale
				coef = malus_decrase_infamy if add >= 0.0 else -1.0

			_:
				# Logique par défaut si non reconnue
				push_warning("Attention cas non pris en compte !")
				coef = 1.0 if add >= 0.0 else malus_decrase_infamy

		# 3. Calcul de la Contribution de l'Infamie (sans abs())
		var potential_infamy_contribution = (add * weight) * coef
		# 4. Gestion de la limite de poids maximum (Infamie positive)
		# S'applique uniquement si la contribution est positive et qu'elle dépasse le max.
		if points + potential_infamy_contribution > max_effect_weight and potential_infamy_contribution > 0:
			add = 0.0
			potential_infamy_contribution = 0.0

		# 5. Accumulation et Enregistrement
		points += potential_infamy_contribution
		#print("cara: %s   valeur: %s   infamy: %s   total_inf: %s" % [key, add, potential_infamy_contribution, points])
		if add != 0.0:
			if effects.has(key):
				effects[key] += add
			else:
				effects[key] = add
		else:
			# Si la valeur est 0, on la garde dans une liste pour le rattrapage.
			keys_with_zero_value.append(key)
	   
	var effects_count = effects.size()
	var needed_count = min_effects_count - effects_count
	
	if needed_count > 0:
		keys_with_zero_value.shuffle()
		var keys_to_fix = keys_with_zero_value.slice(0, needed_count - 1)
		
		for key in keys_to_fix:
			var config = effects_cara.get(key)
			
			# Recalculer une valeur non nulle pour cet effet
			var min_val = config.min_val
			var max_val = config.max_val
			var new_add: float = 0.0
			
			# S'assurer d'une valeur non nulle (en évitant la limite de 0 si elle existe)
			if config.type == "int":
				# Si la plage est 0-0, on force à 1. Sinon on prend le minimum > 0 ou < 0
				if max_val == 0 and min_val == 0:
					new_add = 1.0
				else:
					# On recalcule, sachant qu'on pourrait retomber sur 0.
					# Pour garantir le non-zéro, il faudrait modifier la plage de randi_range
					new_add = float(randi_range(int(min_val), int(max_val)))
					if new_add == 0.0: new_add = 0.1 # On force une petite valeur si on retombe sur 0.
			else:
				new_add = snapped(randf_range(min_val, max_val), 0.001)
				if new_add == 0.0: new_add = 0.001 # On force une petite valeur si on retombe sur 0.

			# Mettre à jour les effets
			#on prend en compte les bonus
			var multiplicators: int = 0
			for mult in StatsManager.malus_and_gain_multi.values():
				multiplicators += mult
			var add_with_mod = new_add
			
			if multiplicators != 0:
				add_with_mod = new_add * (1 + (multiplicators/100))
				
			
			print("old_add: %s\new_add:%s" % [new_add,add_with_mod])
			effects[key] = add_with_mod
			
	# L'infamie finale est le score cumulé (négatif, nul ou positif)
	effects["infamy"] = points
	return effects
