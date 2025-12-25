extends StackScript

func execute() -> Dictionary:
	var shield_value = calcul_effect_value(caster)

	return {
		"caster": caster,
		"targets": [caster], # self-buff
		"action_type": "Shield",
		"effects": [
			{
				"value": shield_value,
				"type": "Shield"
			}
		]
	}
