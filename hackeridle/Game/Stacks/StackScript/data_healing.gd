extends StackScript

func execute() -> Dictionary:
	var heal_value: int = int(calcul_effect_value(caster))

	return {
		"caster": caster,
		"action_type": "Heal",
		"targetEffects": [
			{
				"target": caster, # self-heal
				"effects": [
					{
						"value": heal_value,
						"type": "Heal"
					}
				]
			}
		]
	}
