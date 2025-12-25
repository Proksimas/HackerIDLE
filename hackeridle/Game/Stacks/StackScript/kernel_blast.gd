extends StackScript

func execute() -> Dictionary:
	if targets.is_empty():
		return {
			"caster": caster,
			"targets": [],
			"action_type": "Damage",
			"effects": []
		}

	var damages = calcul_effect_value(caster)

	return {
		"caster": caster,
		"targets": targets, # frappe toutes les cibles
		"action_type": "Damage",
		"effects": [
			{
				"value": damages,
				"type": "HP"
			}
		]
	}
