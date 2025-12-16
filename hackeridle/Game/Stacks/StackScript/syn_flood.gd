extends StackScript


func execute() -> Dictionary:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	var dict = {}
	var damages = calcul_effect_value(caster)
	dict = {"caster": caster,
			"targets": [targets[0]],
			"action_type": "Damage",
			"effects":
				{"value": damages, 
				"type": "HP"}
			}
	targets[0].take_damage(damages)
	return dict
	
