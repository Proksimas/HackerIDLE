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
const MAX_POSITIVE_INFAMY_PER_CHOICE = 40
const MIN_NON_ZERO_EFFECTS_PER_CHOICE = 1
const BENEFIT_INFAMY_MULTIPLIER = 1.35
const MALUS_INFAMY_REDUCTION_RATIO = 0.20
# le weight est le ratio de 1 unité de la variable pour 1 unité d’infam
# les valeurs en % devront avoir un /10 
# NOUVEAU DICTIONNAIRE OPTIMISÉ (avec les paramètres pour build_values)
# benefit_sign: 1 = une valeur positive aide le joueur, -1 = une valeur negative aide le joueur.
var effects_cara = {
	# --- Effets de base/pourcentage purs (Logique Fusionnée 'default') ---

	"xp_click_base":        {"freq": 12, "weight": 18, "min_val": 1, "max_val": 4, "type": "int", "benefit_sign": 1},
	#"knowledge_click_base": {"freq": 18, "weight": 14, "min_val": 1, "max_val": 7, "type": "int", "benefit_sign": 1},
	
	"xp_click_perc":        {"freq": 28, "weight": 45, "min_val": 0.02, "max_val": 0.3, "type": "float", "benefit_sign": 1},
	"knowledge_click_perc": {"freq": 35, "weight": 40, "min_val": 0.02, "max_val": 0.3, "type": "float", "benefit_sign": 1},
	
 
	"perc_from_gold":       {"freq": 55, "weight": 8, "min_val": 0.05, "max_val": 0.4, "type": "float", "benefit_sign": 1},
	"perc_from_knowledge":  {"freq": 55, "weight": 8, "min_val": 0.05, "max_val": 0.4, "type": "float", "benefit_sign": 1},
	"perc_from_brain_xp":   {"freq": 65, "weight": 10, "min_val": 0.05, "max_val": 0.4, "type": "float", "benefit_sign": 1},

	"hack_gold_perc":                 {"freq": 45, "weight": 35, "min_val": -0.3, "max_val": 0.3, "type": "float", "benefit_sign": 1},
	"learning_items_knowledge_perc":  {"freq": 35, "weight": 35, "min_val": -0.3, "max_val": 0.3, "type": "float", "benefit_sign": 1},

	"hack_time_perc":               {"freq": 38, "weight": 40, "min_val": -0.25, "max_val": 0.25, "type": "float", "benefit_sign": -1},
	"hack_cost_perc":               {"freq": 38, "weight": 35, "min_val": -0.25, "max_val": 0.25, "type": "float", "benefit_sign": -1},
	"learning_items_cost_perc":     {"freq": 42, "weight": 35, "min_val": -0.25, "max_val": 0.25, "type": "float", "benefit_sign": -1}
}

var event_profiles = {
	"neutral": {
		"freq": 45,
		"min_keys": 1,
		"max_keys": 3,
		"value_bias": "any",
		"infamy_multiplier": 1.0,
		"allowed_effects": []
	},
	"risky": {
		"freq": 25,
		"min_keys": 2,
		"max_keys": 4,
		"value_bias": "benefit",
		"infamy_multiplier": 1.25,
		"allowed_effects": [
			"xp_click_base",
			"knowledge_click_base",
			"xp_click_perc",
			"knowledge_click_perc",
			"hack_gold_perc",
			"hack_time_perc",
			"hack_cost_perc",
			"perc_from_brain_xp"
		]
	},
	"redemption": {
		"freq": 15,
		"min_keys": 1,
		"max_keys": 3,
		"value_bias": "malus",
		"infamy_multiplier": 1.0,
		"allowed_effects": [
			"hack_gold_perc",
			"learning_items_knowledge_perc",
			"hack_time_perc",
			"hack_cost_perc",
			"learning_items_cost_perc"
		]
	},
	"mixed": {
		"freq": 10,
		"min_keys": 2,
		"max_keys": 4,
		"value_bias": "mixed",
		"infamy_multiplier": 1.0,
		"allowed_effects": [
			"hack_gold_perc",
			"learning_items_knowledge_perc",
			"hack_time_perc",
			"hack_cost_perc",
			"learning_items_cost_perc",
			"xp_click_perc",
			"knowledge_click_perc"
		]
	},
	"instant_reward": {
		"freq": 5,
		"min_keys": 1,
		"max_keys": 2,
		"value_bias": "benefit",
		"infamy_multiplier": 1.1,
		"allowed_effects": [
			"perc_from_gold",
			"perc_from_knowledge",
			"perc_from_brain_xp"
		]
	}
}
	
func event_setup(_id: int) -> bool:
	"""On setup l'event en traduisant ses informations basiques. Puis on appelle 
	la fonction de création des effets"""
	event_id = _id
	event_titre_id = "event_{id}_titre".format({"id": _id})
	event_description_id = "event_{id}_desc".format({"id": _id})
	event_choice_1["texte_id"] = "event_{id}_choix1".format({"id": _id})
	event_choice_2["texte_id"] = "event_{id}_choix2".format({"id": _id})
	create_effects()
	return true

	

func create_effects():
	"""On va créer les effets en prenant en compte la fréquence d'apparition
	et le poids de l'effet
	L'infamy correspond à la somme des effets, avec une variation de x%
	Si le choice 1 a un weight positif, le choice 2 doiten avoir un equivalent
	(avec legere variation) en négatif"""
	# on choisit les keys selon leurs fréquences
	var lst_choices_name = ["choice_a", "choice_b"]
	for choice_name in lst_choices_name:

		var profile = pick_event_profile()
		var keys_chosen = get_keys_for_profile(profile)
		var effects = build_values(keys_chosen, MIN_NON_ZERO_EFFECTS_PER_CHOICE, MAX_POSITIVE_INFAMY_PER_CHOICE, MALUS_INFAMY_REDUCTION_RATIO, profile)
		
		match choice_name:
			"choice_a":
				event_choice_1["effects"] = effects
			_:
				event_choice_2["effects"] = effects

func pick_event_profile() -> Dictionary:
	var total_weight: int = 0
	for profile in event_profiles.values():
		total_weight += int(profile.get("freq", 0))
	var roll := randi_range(1, max(total_weight, 1))
	var cursor := 0
	for profile in event_profiles.values():
		cursor += int(profile.get("freq", 0))
		if roll <= cursor:
			return profile
	return event_profiles["neutral"]

func get_keys_for_profile(profile: Dictionary) -> Array:
	var min_keys: int = int(profile.get("min_keys", MIN_KEYS))
	var max_keys: int = int(profile.get("max_keys", MAX_KEYS))
	min_keys = clamp(min_keys, MIN_KEYS, MAX_KEYS)
	max_keys = clamp(max_keys, min_keys, MAX_KEYS)

	var allowed_effects: Array = profile.get("allowed_effects", [])
	if allowed_effects.is_empty():
		allowed_effects = effects_cara.keys()
	return get_keys(min_keys, max_keys, allowed_effects)

func get_keys(min_keys: int, max_keys: int, allowed_effects: Array = []) -> Array:
	var selected_keys = []
	
	var nb_events_target = randi_range(min_keys, max_keys)
	var all_keys = allowed_effects.duplicate()
	if all_keys.is_empty():
		all_keys = effects_cara.keys()
	var valid_keys = []
	for key_name in all_keys:
		if effects_cara.has(key_name):
			valid_keys.append(key_name)
	if valid_keys.is_empty():
		valid_keys = effects_cara.keys()
	valid_keys.shuffle()
	for key_name in valid_keys:
		if selected_keys.size() >= nb_events_target:
			break
		var frequency = effects_cara[key_name].freq
		if randi_range(1, 100) <= frequency:
			selected_keys.append(key_name)
	if selected_keys.size() < min_keys:
		for key_name in valid_keys:
			if selected_keys.size() >= min_keys:
				break
			if not selected_keys.has(key_name):
				selected_keys.append(key_name)
	if selected_keys.is_empty():
		selected_keys.append(valid_keys[0])
	return selected_keys
	# NOTE: Le dictionnaire 'effects_cara' doit être celui optimisé avec les champs min_val, max_val, type et benefit_sign.
# max_positive_infamy est la limite supérieure positive de l'infamie.
# min_non_zero_effects est le nombre minimum d'effets non nuls dans le résultat.

func is_player_benefit(effect_name: String, value: float) -> bool:
	if effect_name == "infamy":
		return value < 0.0
	var config = effects_cara.get(effect_name)
	if config == null:
		return false
	var benefit_sign: int = int(config.get("benefit_sign", 1))
	return value * benefit_sign > 0.0

func is_malus_for_player(effect_name: String, value: float) -> bool:
	if value == 0.0:
		return false
	return not is_player_benefit(effect_name, value)

func get_infamy_contribution(effect_name: String, value: float, weight: float, malus_infamy_reduction_ratio: float) -> float:
	if value == 0.0:
		return 0.0
	var magnitude = abs(value * weight)
	if is_player_benefit(effect_name, value):
		return magnitude * BENEFIT_INFAMY_MULTIPLIER
	return -magnitude * malus_infamy_reduction_ratio

func get_profile_value_bias(profile: Dictionary, effect_index: int) -> String:
	var value_bias: String = str(profile.get("value_bias", "any"))
	if value_bias == "mixed":
		return "benefit" if effect_index % 2 == 0 else "malus"
	return value_bias

func roll_effect_value(effect_name: String, profile: Dictionary, effect_index: int = 0) -> float:
	var config = effects_cara.get(effect_name)
	if config == null:
		return 0.0

	var min_val: float = float(config.min_val)
	var max_val: float = float(config.max_val)
	var benefit_sign: int = int(config.get("benefit_sign", 1))
	var value_bias := get_profile_value_bias(profile, effect_index)

	if value_bias == "benefit":
		if benefit_sign >= 0:
			min_val = max(min_val, 0.001)
		else:
			max_val = min(max_val, -0.001)
	elif value_bias == "malus":
		if benefit_sign >= 0:
			max_val = min(max_val, -0.001)
		else:
			min_val = max(min_val, 0.001)

	if min_val > max_val:
		min_val = float(config.min_val)
		max_val = float(config.max_val)

	if config.type == "int":
		var int_min := int(ceil(min_val))
		var int_max := int(floor(max_val))
		if int_min > int_max:
			int_min = int(ceil(float(config.min_val)))
			int_max = int(floor(float(config.max_val)))
		if int_min > int_max:
			return 0.0
		return float(randi_range(int_min, int_max))
	return snapped(randf_range(min_val, max_val), 0.001)

func build_values(keys: Array, min_non_zero_effects: int, max_positive_infamy: float, malus_infamy_reduction_ratio: float, profile: Dictionary = {}) -> Dictionary:
	# Renommage interne du paramètre pour la clarté :
	var min_effects_count: int = min_non_zero_effects
	
	var effects: Dictionary = {}
	var points: float = 0.0 # Peut être négatif/nul
	var profile_infamy_multiplier: float = float(profile.get("infamy_multiplier", 1.0))
	
	keys.shuffle()
	var keys_with_zero_value: Array = []
	var effect_index := 0
 
	for key in keys:
		var config = effects_cara.get(key)
		
		if config == null: continue

		var add: float = roll_effect_value(key, profile, effect_index)
		effect_index += 1
		var weight: float = config.weight
		
		# 1. Calcul de la valeur aléatoire (add)
		var potential_infamy_contribution = get_infamy_contribution(key, add, weight, malus_infamy_reduction_ratio) * profile_infamy_multiplier
		# 4. Gestion de la limite de poids maximum (Infamie positive)
		# S'applique uniquement si la contribution est positive et qu'elle dépasse le max.
		if points + potential_infamy_contribution > max_positive_infamy and potential_infamy_contribution > 0:
			add = 0.0
			potential_infamy_contribution = 0.0

		# 5. Accumulation et Enregistrement
		points += potential_infamy_contribution
		#print("cara: %s   valeur: %s   infamy: %s   total_inf: %s" % [key, add, potential_infamy_contribution, points])
		if add != 0.0:
			if effects.has(key):
				effects[key] += add_multiplicators(add)
			else:
				effects[key] = add_multiplicators(add)
				#print("key: %s   old_value: %s   new_value: %s" % [key, add, effects[key]])
		else:
			# Si la valeur est 0, on la garde dans une liste pour le rattrapage.
			keys_with_zero_value.append(key)
		
	   
	var effects_count = effects.size()
	var needed_count = min_effects_count - effects_count
	
	if needed_count > 0:
		keys_with_zero_value.shuffle()
		var keys_to_fix = keys_with_zero_value.slice(0, needed_count)
		for key in keys_to_fix:
			var config = effects_cara.get(key)
			
			# Recalculer une valeur non nulle pour cet effet
			var new_add: float = roll_effect_value(key, profile, effect_index)
			effect_index += 1
			
			if new_add == 0.0:
				new_add = 1.0 if config.type == "int" else 0.001

			# Mettre à jour les effets
			#on prend en compte les bonus

				
			effects[key] = add_multiplicators(new_add)
			var new_contribution := get_infamy_contribution(key, new_add, config.weight, malus_infamy_reduction_ratio) * profile_infamy_multiplier
			points += new_contribution
			
	# L'infamie finale est le score cumulé (négatif, nul ou positif)
	var sum: int = 0
	for value in EventsManager.add_infamy_events.values():
		sum += value
	
	effects["infamy"] = points + sum
	return effects

func add_multiplicators(value_to_change:float):
	"""On ajoute les modificateurs sur les gains"""
	var multiplicators: int = 0
	for mult in EventsManager.malus_and_gain_multi.values():
		multiplicators += mult
	var add_with_mod: float
	
	if multiplicators != 0:
		add_with_mod = value_to_change * (1.0 + (multiplicators/100.0))
	else:
		add_with_mod = value_to_change
	return add_with_mod
	
