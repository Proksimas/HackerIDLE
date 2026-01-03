extends StackScript

func execute() -> Dictionary:
	var shield_value = calcul_effect_value(caster)

	return {
		"caster": caster,
		"action_type": "Shield",
		"targetEffects": [
			{
				"target": caster, # self-buff
				"effects": [
					{
						"value": shield_value,
						"type": "Shield"
					}
				]
			}
		]
	}
