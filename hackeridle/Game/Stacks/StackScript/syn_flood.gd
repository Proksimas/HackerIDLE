extends StackScript

func execute() -> Dictionary:
	var damages = calcul_effect_value(caster)

	return {
		"caster": caster,
		"targets": [targets[0]],
		"action_type": "Damage",
		"effects": [
			{
				"value": damages,
				"type": "HP"
			}
		]
	}
