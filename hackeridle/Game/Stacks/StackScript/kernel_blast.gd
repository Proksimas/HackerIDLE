extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		return {
			"caster": caster,
			"action_type": "Damage",
			"targetEffects": []
		}

	var damages = calcul_effect_value(caster)

	# Un hit identique sur toutes les cibles
	var target_effects: Array = []
	for t: Entity in targets:
		target_effects.append({
			"target": t,
			"effects": [
				{
					"value": damages,
					"type": "HP"
				}
			]
		})

	return {
		"caster": caster,
		"action_type": "Damage",
		"targetEffects": target_effects
	}
