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



func event_setup(_id, _choice_1_effects, _choice_2_effects) -> void:
	event_id = _id
	event_titre_id = "event_{id}_titre".format({"id": _id})
	event_description_id = "event_{id}_desc".format({"id": _id})
	event_choice_1["texte_id"] = "event_{id}_choix1".format({"id": _id})
	event_choice_1["effects"] = _choice_1_effects
	event_choice_2["texte_id"] = "event_{id}_choix2".format({"id": _id})
	event_choice_2["effects"] = _choice_2_effects
	

func apply_effects(effects: Array):
	var stat_of_effect: String
	#for effect in effects:
		#stat_of_effect = effect
		#match effect:
			
