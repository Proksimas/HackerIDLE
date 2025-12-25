extends StackScript

func execute() -> Dictionary:
	var heal_value: int = int(calcul_effect_value(caster))

	return {
		"caster": caster,
		"targets": [caster], # self-heal (Hacker)
		"action_type": "Heal",
		"effects": [
			{
				"value": heal_value,
				"type": "Heal"
			}
		]
	}
